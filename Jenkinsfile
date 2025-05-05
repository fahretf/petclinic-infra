pipeline {
  agent any

  options {
    buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '30'))
    skipDefaultCheckout() 
  }

  stages {
    stage('Clean up ') {
        steps {
            deleteDir()
            sh 'docker prune -af'
        }
    }
    stage('Validate PR') {
  when {
    allOf {
       changeRequest()                         
       expression { env.CHANGE_TARGET == 'develop' }  
    }
  }
  stages {
    stage('Build Frontend') {
      agent { docker { image 'node:20' } }
      steps {
        dir('petclinicfe') {
          sh 'npm ci'
          sh 'npm run build'
        }
      }
    }
    stage('Build Backend') {
      agent { docker { image 'maven:3-eclipse-temurin-17' } }
      steps {
        dir('petclinicbe') {
          sh 'mkdir -p logs'
          sh 'mvn clean install -DLOG_PATH=logs'
        }
      }
    }
  }
}

    stage('Deploy') {
      when {
        allOf {
          branch 'develop'
          not { changeRequest() }         
        }
      }
      stages {
        stage('Build Frontend') {
          agent { docker { image 'node:20' } }
          steps {
            echo 'Building frontend (deploy)...'
            dir('petclinicfe') {
              sh 'npm ci'
              sh 'npm run build'
            }
          }
        }
        stage('Build Backend') {
          agent { docker { image 'maven:3-eclipse-temurin-17' } }
          steps {
            echo 'Building backend...'
            dir('petclinicbe') {
              sh 'mkdir -p logs'
              sh 'mvn clean install -DLOG_PATH=logs'
            }
          }
        }
        stage('Build & Push Images') {
          agent { docker { image 'docker:25.0.3-cli' } }
          steps {
            echo 'Building and pushing  images...'
            withCredentials([usernamePassword(
              credentialsId: 'docker-registry',
              usernameVariable: 'DOCKER_USER',
              passwordVariable: 'DOCKER_PASS'
            )]) {
              sh '''
                echo "$DOCKER_PASS" | \
                  docker login registry.praksa.abhapp.com \
                    --username "$DOCKER_USER" --password-stdin

                docker build -t registry.praksa.abhapp.com/petclinicbe:${GIT_COMMIT:0:7} petclinicbe
                docker push registry.praksa.abhapp.com/petclinicbe:${GIT_COMMIT:0:7}

                docker build -t registry.praksa.abhapp.com/petclinicfe:${GIT_COMMIT:0:7} petclinicfe
                docker push registry.praksa.abhapp.com/petclinicfe:${GIT_COMMIT:0:7}
              '''
            }
          }
        }
        stage('Deploy App') {
          steps {
            script {
              def shortCommit = env.GIT_COMMIT.take(7)
              writeFile file: '.env', text: "IMAGE_TAG=${shortCommit}\n"
            }
            sh '''
              docker-compose pull
              docker-compose up -d
            '''
          }
        }
      }
    }
  }

  post {
    always {
      echo 'Cleaning workspace...'
      deleteDir()
    }

    success {
      script {
        if (!env.CHANGE_ID && env.BRANCH_NAME == 'develop') {
          def shortCommit = env.GIT_COMMIT.take(7)
          withCredentials([string(credentialsId: 'slack-bot-token', variable: 'SLACK_TOKEN')]) {
            sh """
              curl -X POST https://slack.com/api/chat.postMessage \
                -H "Authorization: Bearer $SLACK_TOKEN" \
                -H "Content-type: application/json" \
                --data '{
                  "channel": "#jenkins-test",
                  "text": "*Build Succeeded* for `${env.BRANCH_NAME}` (`${shortCommit}`)"
                }'
            """
          }
        }
      }
    }

    failure {
      script {
        if (!env.CHANGE_ID && env.BRANCH_NAME == 'develop') {
          def shortCommit = env.GIT_COMMIT.take(7)
          withCredentials([string(credentialsId: 'slack-bot-token', variable: 'SLACK_TOKEN')]) {
            sh """
              curl -X POST https://slack.com/api/chat.postMessage \
                -H "Authorization: Bearer $SLACK_TOKEN" \
                -H "Content-type: application/json" \
                --data '{
                  "channel": "#jenkins-test",
                  "text": ":x: *Build Failed* for `${env.BRANCH_NAME}` (`${shortCommit}`)"
                }'
            """
          }
        }
      }
    }
  }
}
