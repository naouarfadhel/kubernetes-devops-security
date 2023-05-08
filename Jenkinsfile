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
              sh "mvn org.pitest:pitest-maven:mutationCoverage" 
            }
            post {
              always {
                pitmutation mutationStatsFile : '**/target/pit-reports/**/mutations.xml'
             }
            }
        }
      stage('SonarQube - SAST') {
            steps {
              withSonarQubeEnv('SonarQube'){
                sh "mvn clean verify sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.projectName='numeric-application' -Dsonar.host.url=http://mfnaouar-pfe.eastus.cloudapp.azure.com:9000 -Dsonar.token=sqp_350be401ba8281b6e93a58279bea7bc01769d54e"
              }
              timeout(time:2, unit: 'MINUTES'){
                script {
                  waitForQualityGate abortPipeline:true
                }
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