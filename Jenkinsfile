pipeline {
    agent any
    
    options {
        timeout(time: 10, unit: 'MINUTES')
        timestamps()
    }
    
    parameters {
        string(
            name: 'environment_id',
            description: 'ID of the environment of this deployment',
        )
        string(
            name: 'issue_key',
            description: 'Issue key associated with this deployment',
        )
        string(
            name: 'environment_name',
            description: 'Name of the environment of this deployment',
        )
        choice (
            name: 'environment_type',
            description: 'Type of environment in which the pipeline will run',
            choices: ['testing', 'production'],
        )
        string(
            description: 'Branch that will be pulled',
            name: 'git_branch',
        )
        credentials(
            credentialType: 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl',
            description: 'Username used by Jenkins in the EC2 instance',
            name: 'ec2_username',
            required: true
        )
        credentials(
            credentialType: 'org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl',
            description: 'Private IP of the instance',
            name: 'ec2_host',
            required: true
        )
        credentials(
            credentialType: 'com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey',
            description: 'Private SSH key of the instance',
            name: 'ssh_key',
            required: true
        )
        booleanParam(
            name: 'terraform_init',
            description: 'Apply terraform init?',
        )
        choice(
            name: 'terraform_commands',
            description: 'Terraform command(s) to be executed',
            choices: ['validate','validate-plan','validate-plan-apply'],
        )
    }
    
    environment {
        TERRAFORM_DIR = '/home/ubuntu/Personal-Finance-Manager-Terraform'
    }
    
    stages {
        stage('Send notification') {
            steps {
                sendDeploymentInfoSlack('pipeline in progress')
                sendDeploymentInfoJira('in_progress')
            }
        }
        stage('Check Connection') {
            steps {
                script {
                    def connectionVars = getConnectionCredentials()
                    sshagent([params.ssh_key]) {
                        checkSSHConnection(connectionVars)
                    }
                }
            }
        }
        stage('Execution') {
            steps {
                script {
                    echo 'Starting execution'
                    def envVars = getAllConnectionCredentials()
                    sshagent([params.ssh_key]) {
                        runTerraformCommands(envVars)
                    }
                }
            }
            post {
                success {
                    echo 'Execution successful!'
                    proceedMessage()
                }
                failure {
                    echo 'Execution failed! Check logs above.'
                }
            }
        }
    }
    
    post {
        success {
            echo 'Pipeline completed successfully!'
            sendDeploymentInfoJira('successful')
            sendDeploymentInfoSlack('execution successful')
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
            sendDeploymentInfoJira('failed')
            sendDeploymentInfoSlack('execution failed')
        }
        unstable {
            echo 'Pipeline is unstable.'
            sendDeploymentInfoJira('unknown')
            sendDeploymentInfoSlack('execution unstable')
        }
    }
}
