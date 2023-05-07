pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' 
            }
        }
      stage('Unit Tests') {
            steps {
              sh "mvn test" 
            }
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
        }
      stage('Docker Build & pull') {
            steps {
              /* il faut se connecter avec docker hub via la VM */
              withDockerRegistry([credentialsId:"docker-hub",url:""]){
                sh 'printenv'
                sh 'docker build -t mfnaouar6/numeric-app:""$GIT_COMMIT"" .' 
                sh 'docker push mfnaouar6/numeric-app:""$GIT_COMMIT""'
              } 
            }
        }
    }
}