pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' 
            }
        }
      stage('Unit Tests - Juint & JaCoCo') {
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
      stage('Mutation Tests - PIT') {
            steps {
              sh "mvn ong.pitest:pitest-maven:mutationCoverage" 
            }
            post {
              always {
                pitmutation mutationStatsFile : '**/target/pit-reports/**/mutations.xml'
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
      stage('K8S Deployment - DEV') {
            steps {
              withKubeConfig([credentialsId: 'kubeconf']) {
                sh "sed -i 's#replace#mfnaouar6/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                sh "kubectl apply -f k8s_deployment_service.yaml"
              }
            }
        }
        
    }
}