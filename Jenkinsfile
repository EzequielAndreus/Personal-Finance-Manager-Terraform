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

// Helper function to send info to Slack
def sendDeploymentInfoSlack(String message) {
    withCredentials([string(credentialsId: 'jira-ticket-browse', variable: 'TICKET_LINK')]) {
        slackSend(
            channel: "terraform-executions",
            message: "${TICKET_LINK}${params.issue_key} - ${message}"
        )
    }
}

// Helper function to send info to Jira
def sendDeploymentInfoJira(String state) {
    jiraSendDeploymentInfo(
        environmentId: "${params.environment_id}",
        environmentName: "${params.environment_name}",
        environmentType: "${params.environment_type}",
        state: "${state}",
        issueKeys: ["${params.issue_key}"]
    )
}

// Helper function to get connection credentials
def getConnectionCredentials() {
    def creds = [:]
    withCredentials([
        string(credentialsId: params.ec2_username, variable: 'EC2_USERNAME'),
        string(credentialsId: params.ec2_host, variable: 'EC2_HOST')
    ]) {
        creds = [
            EC2_USERNAME: env.EC2_USERNAME,
            EC2_HOST: env.EC2_HOST
        ]
    }
    return creds
}

// Helper function to get all deployment credentials
def getAllConnectionCredentials() {
    def creds = [:]
    withCredentials([
        string(credentialsId: params.ec2_username, variable: 'EC2_USERNAME'),
        string(credentialsId: params.ec2_host, variable: 'EC2_HOST'),
    ]) {
        creds = [
            EC2_USERNAME: env.EC2_USERNAME,
            EC2_HOST: env.EC2_HOST,
            GIT_BRANCH: params.git_branch
        ]
    }
    return creds
}

// Helper function to check SSH connection
def checkSSHConnection(Map connectionVars) {
    echo "Checking SSH connectivity to ${connectionVars.EC2_USERNAME}@${connectionVars.EC2_HOST}..."
    
    def result = sh(
        script: """
            timeout 5s bash -c '
                ssh -o BatchMode=yes -o ConnectTimeout=5 \
                -o StrictHostKeyChecking=no ${connectionVars.EC2_USERNAME}@${connectionVars.EC2_HOST} "echo ok" \
                2>/dev/null
            '
        """,
        returnStatus: true
    )
    
    if (result != 0) {
        error "SSH connection to ${connectionVars.EC2_HOST} failed! Aborting pipeline."
    } else {
        echo "SSH connection to ${connectionVars.EC2_HOST} verified successfully."
        proceedMessage()
    }
}

// Helper function to execute commands in the EC2
def runTerraformCommands(Map envVars) {

    def setupScript = """
        set -e
        echo "Navigating to terraform directory..."
        cd ${TERRAFORM_DIR}
        echo "Pulling latest changes..."
        git pull origin "${envVars.GIT_BRANCH}"
    """
    
    sh """
        ssh -o StrictHostKeyChecking=no "${envVars.EC2_USERNAME}@${envVars.EC2_HOST}" \
            GIT_BRANCH="${envVars.GIT_BRANCH}" \
            bash -s << 'SETUP_SCRIPT'
${setupScript}
SETUP_SCRIPT
    """
    
    // Run terraform init if selected
    if (params.terraform_init) {
        echo "Running terraform init..."
        def initScript = """
            set -e
            cd ${TERRAFORM_DIR}/TF-REPO
            terraform init
            echo "Terraform init completed successfully."
        """
        
        sh """
            ssh -o StrictHostKeyChecking=no "${envVars.EC2_USERNAME}@${envVars.EC2_HOST}" \
                bash -s << 'INIT_SCRIPT'
${initScript}
INIT_SCRIPT
        """
        
        echo "Terraform init completed. Waiting for confirmation..."
        proceedMessage()
    }
    
    // Parse and run terraform commands with confirmations between each
    def commands = params.terraform_commands.split('-')
    
    commands.each { cmd ->
        echo "Running terraform ${cmd}..."
        
        def commandScript = """
            set -e
            cd ${TERRAFORM_DIR}/TF-REPO
            terraform ${cmd}
            echo "Terraform ${cmd} completed successfully."
        """
        
        sh """
            ssh -o StrictHostKeyChecking=no "${envVars.EC2_USERNAME}@${envVars.EC2_HOST}" \
                bash -s << 'COMMAND_SCRIPT'
${commandScript}
COMMAND_SCRIPT
        """
        
        echo "Terraform ${cmd} completed. Waiting for confirmation to proceed..."
        proceedMessage()
    }
    
    echo "All Terraform commands executed successfully."
}

def proceedMessage() {
    timeout(time: 5, unit: 'MINUTES') {
        input message: 'Proceed to the next stage?', ok: 'Proceed'
    }
}