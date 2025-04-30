pipeline {
    agent any
    stages {
        stage('Build frontend') {
            agent {
                docker {
                    image 'node:20'
                }
            }
            steps {
                echo 'Building frontend...'
                sh '''
                cd petclinicfe
                npm install
                npm run build
            '''
            }
        }
        stage('Build backend') {
            agent {
                docker {
                    image 'maven:3-eclipse-temurin-17'
                }
            }
            steps {
                echo 'Building backend...'
                sh '''
                    cd petclinicbe
                    mkdir -p logs
                    mvn clean install -DLOG_PATH=logs
                '''
            }
        }

        stage('Build and push images') {
            when {
                allOf {
                    expression { env.CHANGE_ID == null }
                    branch 'develop'
                }
            }
            agent {
                docker {
                    image 'docker:25.0.3-cli'
                }
            }
            steps {
                echo 'Building and pushing the images to our registry...'
                withCredentials([usernamePassword(credentialsId: 'docker-registry', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login registry.praksa.abhapp.com --username "$DOCKER_USER" --password-stdin

                        docker build -t registry.praksa.abhapp.com/petclinicbe:${GIT_COMMIT:0:7} petclinicbe
                        docker push registry.praksa.abhapp.com/petclinicbe:${GIT_COMMIT:0:7}

                        docker build -t registry.praksa.abhapp.com/petclinicfe:${GIT_COMMIT:0:7} petclinicfe
                        docker push registry.praksa.abhapp.com/petclinicfe:${GIT_COMMIT:0:7}
                    '''
                }
            }
        }

        stage('Deploy app') {
            when {
                allOf {
                    expression { env.CHANGE_ID == null }
                    branch 'develop'
                }
            }

            steps {
                script {
                    def shortCommit = env.GIT_COMMIT.take(7)
                    writeFile file: '.env', text: "IMAGE_TAG=${shortCommit}\n"

                    sh '''
                    docker-compose pull
                    docker-compose up -d
                '''
                }
            }
        }
    }

    post {
        success {
            script {
                def shortCommit = env.GIT_COMMIT.take(7)
                withCredentials([string(credentialsId: 'slack-bot-token', variable: 'SLACK_TOKEN')]) {
                    sh """
                    curl -X POST https://slack.com/api/chat.postMessage \
                      -H "Authorization: Bearer $SLACK_TOKEN" \
                      -H "Content-type: application/json" \
                      --data '{
                          "channel": "#jenkins-test",
                          "text": ":rocket: *Build Succeeded* for `${env.BRANCH_NAME}` (`${shortCommit}`)"
                      }'
                """
                }
            }
        }

        failure {
            script {
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
