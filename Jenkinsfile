pipeline {
    agent any

    options {
        buildDiscarder(logRotator(numToKeepStr: '10', daysToKeepStr: '30'))
    }

    stages {
        stage('Clean up') {
            steps {
                deleteDir()
                sh 'docker system prune -af'
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
                    agent {
                        docker {
                            image 'node:20'
                            args '-v /var/jenkins_cache/npm:/home/node/.npm'
                        }
                    }
                    steps {
                        dir('petclinicfe') {
                            sh 'npm install'
                            sh 'npm run build'
                        }
                    }
                }
                stage('Build Backend') {
                    agent {
                        docker {
                            image 'maven:3-eclipse-temurin-17'
                            args '-v /var/jenkins_cache/m2:/home/jenkins/.m2'
                        }
                    }
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
                    agent {
                        docker {
                            image 'node:20'
                        }
                    }
                    steps {
                        echo 'Building frontend (deploy)...'
                        dir('petclinicfe') {
                            sh 'npm ci'
                            sh 'npm run build'
                        }
                    }
                }

                stage('Build Backend') {
                    agent {
                        docker {
                            image 'maven:3-eclipse-temurin-17'
                        }
                    }
                    steps {
                        echo 'Building backend...'
                        dir('petclinicbe') {
                            sh 'mkdir -p logs'
                            sh 'mvn clean install -DLOG_PATH=logs'
                        }
                    }
                }

                stage('Build & Push Images') {
                    agent any
                    environment {
                        SHORT_SHA = "${env.GIT_COMMIT.take(7)}"
                    }
                    steps {
                        echo 'Building and pushing images...'
                        withCredentials([
                            usernamePassword(
                                credentialsId: 'docker-registry',
                                usernameVariable: 'DOCKER_USER',
                                passwordVariable: 'DOCKER_PASS'
                            )
                        ]) {
                            sh '''
                                echo "$DOCKER_PASS" | \
                                docker login registry.praksa.abhapp.com \
                                    --username "$DOCKER_USER" --password-stdin

                                docker build -t registry.praksa.abhapp.com/petclinicbe:$SHORT_SHA petclinicbe
                                docker push registry.praksa.abhapp.com/petclinicbe:$SHORT_SHA

                                docker build -t registry.praksa.abhapp.com/petclinicfe:$SHORT_SHA petclinicfe
                                docker push registry.praksa.abhapp.com/petclinicfe:$SHORT_SHA
                            '''
                        }
                    }
                }

                stage('Deploy App') {
                    agent any
                    environment {
                        PATH = "/usr/local/bin:${env.PATH}"
                    }
                    steps {
                        checkout scm

                        script {
                            def shortCommit = env.GIT_COMMIT.take(7)

                            withCredentials([
                                usernamePassword(
                                    credentialsId: 'docker-registry',
                                    usernameVariable: 'DOCKER_USER',
                                    passwordVariable: 'DOCKER_PASS'
                                ),
                                string(credentialsId: 'postgres-password', variable: 'POSTGRES_PASSWORD'),
                                string(credentialsId: 'gf-smtp-user', variable: 'GF_SMTP_USER'),
                                string(credentialsId: 'gf-smtp-password', variable: 'GF_SMTP_PASSWORD'),
                                string(credentialsId: 'gf-smtp-from-address', variable: 'GF_SMTP_FROM_ADDRESS')
                            ]) {
                                writeFile file: '.env', text: """\
                                    TAG=${shortCommit}
                                    POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
                                    GF_SMTP_USER=${GF_SMTP_USER}
                                    GF_SMTP_PASSWORD=${GF_SMTP_PASSWORD}
                                    GF_SMTP_FROM_ADDRESS=${GF_SMTP_FROM_ADDRESS}
                                """.stripIndent()

                                sh """
                                    echo "$DOCKER_PASS" | docker login registry.praksa.abhapp.com \
                                        --username "$DOCKER_USER" --password-stdin

                                    docker compose pull
                                    docker compose up -d
                                """
                            }
                        }
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
                    withCredentials([
                        string(credentialsId: 'slack-bot-token', variable: 'SLACK_TOKEN')
                    ]) {
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
                    withCredentials([
                        string(credentialsId: 'slack-bot-token', variable: 'SLACK_TOKEN')
                    ]) {
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
