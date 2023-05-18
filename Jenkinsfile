@Library('slack') _
pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "mfnaouar6/numeric-app:${GIT_COMMIT}"
    applicationURL="http://mfnaouar-pfe.eastus.cloudapp.azure.com"
    applicationURI="/increment/99"
  }

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
        }
      stage('Mutation Tests - PIT') {
           steps {
              sh "mvn org.pitest:pitest-maven:mutationCoverage" 
            }
        }
      stage('SonarQube - SAST') {
            steps {
              withSonarQubeEnv('SonarQube'){
                sh "mvn  sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.projectName='numeric-application' -Dsonar.host.url=http://mfnaouar-pfe.eastus.cloudapp.azure.com:9000"
              }
              timeout(time:2, unit: 'MINUTES'){
                script {
                  waitForQualityGate abortPipeline:true
                }
              }
            }
        }
      // stage('Vulnerability Scan - Docker') {
      //   steps {
      //     sh "mvn dependency-check:check"
      //   }
      // }
      stage('Vulnerability Scan - Docker') {
        steps {
          parallel(
            "Dependency Scan": {
              sh "mvn dependency-check:check"
            },
            "Trivy Scan":{
              script{
              try {
                sh "bash trivy-docker-image-scan.sh"
              }
              catch(Exception e) {
                echo "Trivy scan encountered an error, but continuing the pipeline..."
              }
              
              }
             },
            "OPA Conftest":{
              sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
            }
          )
        }
      }
      stage('Docker Build & pull') {
            steps {
              /* il faut se connecter avec docker hub via la VM */
              withDockerRegistry([credentialsId:"docker-hub",url:""]){
                sh 'printenv'
                sh 'sudo docker build -t mfnaouar6/numeric-app:""$GIT_COMMIT"" .' 
                sh 'docker push mfnaouar6/numeric-app:""$GIT_COMMIT""'
              } 
            }
        }
      stage('Vulnerability Scan - Kubernetes') {
        steps {
          parallel(
            "OPA Scan": {
              sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
            },
            "Kubesec Scan": {
              sh "bash kubesec-scan.sh"
            },
            "Trivy Scan":{
              script{
                try {
                  sh "bash trivy-k8s-scan.sh"
                }
                catch(Exception e) {
                  echo "Trivy scan encountered an error, but continuing the pipeline..."
                }
              
              }
            },
          )
        }
      }
      stage('K8S Deployment - DEV') {
        steps {
          parallel(
            "Deployment": {
              withKubeConfig([credentialsId: 'kubeconf']) {
                sh "bash k8s-deployment.sh"
              }
            },
            "Rollout Status": {
              withKubeConfig([credentialsId: 'kubeconf']) {
                sh "bash k8s-deployment-rollout-status.sh"
              }
            }
          )
        }
      }
      stage('Integration Tests - DEV') {
        steps {
          script {
            try {
              withKubeConfig([credentialsId: 'kubeconf']) {
                sh "bash integration-test.sh"
              }
            } catch (e) {
              withKubeConfig([credentialsId: 'kubeconf']) {
                sh "kubectl -n default rollout undo deploy ${deploymentName}"
              }
              throw e
            }
          }
        }
      }
      stage('OWASP ZAP - DAST') {
        steps {
          withKubeConfig([credentialsId: 'kubeconf']) {
            sh 'bash zap.sh'
          }
        }
      }

      // stage('K8S Deployment - DEV') {
      //       steps {
      //         withKubeConfig([credentialsId: 'kubeconf']) {
      //           sh "sed -i 's#replace#mfnaouar6/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
      //           sh "kubectl apply -f k8s_deployment_service.yaml"
      //         }
      //       }
      //   }
        
    }
  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile : '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern : 'target/dependency-check-report.xml'
      publishHTML([allowMissing: false, alwaysLinkToLastBuild: true, keepAll: true, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML Report', reportTitles: 'OWASP ZAP HTML Report'])
      sendNotification currentBuild.result
    }
  }
}