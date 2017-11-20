#!groovy
node('tse-control-repo') {
  sshagent (credentials: ['jenkins-seteam-ssh']) {
    withEnv(['PATH+EXTRA=/usr/local/bin']) {
      checkout scm

      stage('Setup'){
        ansiColor('xterm') {
          sh(script: '''
            export PATH=$PATH:$HOME/.rbenv/bin
            rbenv global 2.3.1
            eval "$(rbenv init -)"
            bundle install
          ''')
        }
      }

      stage('Lint Control Repo'){
        ansiColor('xterm') {
          sh(script: '''
            export PATH=$PATH:$HOME/.rbenv/bin
            rbenv global 2.3.1
            eval "$(rbenv init -)"
            bundle exec rake lint
          ''')
        }
      }

      stage('Syntax Check Control Repo'){
        ansiColor('xterm') {
          sh(script: '''
            export PATH=$PATH:$HOME/.rbenv/bin
            rbenv global 2.3.1
            eval "$(rbenv init -)"
            bundle exec rake syntax --verbose
          ''')
        }
      }

      stage('Validate Puppetfile in Control Repo'){
        ansiColor('xterm') {
          sh(script: '''
            export PATH=$PATH:$HOME/.rbenv/bin
            rbenv global 2.3.1
            eval "$(rbenv init -)"
            bundle exec rake r10k:syntax
          ''')
        }
      }

      stage('Validate Tests Exist'){
        ansiColor('xterm') {
          sh(script: '''
            export PATH=$PATH:$HOME/.rbenv/bin
            rbenv global 2.3.1
            eval "$(rbenv init -)"
            bundle exec rake check_for_spec_tests
          ''')
        }
      }

      stage('Build Artifact'){
        ansiColor('xterm') {
          sshagent (credentials: ['jenkins-seteam-ssh']) {
            sh(script: '''
              export PATH=$PATH:$HOME/.rbenv/bin
              rbenv global 2.3.1
              eval "$(rbenv init -)"
              r10k puppetfile install
              tar --exclude='.git' -zcvf control-repo.tar.gz .
            ''')
          }
        }
        stash name:'cr-mod', includes: 'control-repo.tar.gz'
      }
    }
  }
}

stage('Run Spec Tests') {
  parallel(
    'linux::profile::spec': {
      runSpecTests('linux')
    },
    'windows::profile::spec': {
      runSpecTests('windows')
    }
  )
}


// functions
def linux(){
  withEnv(['PATH+EXTRA=/usr/local/bin']) {
    unstash "cr-mod"
    sh(script: 'tar -zxvf control-repo.tar.gz')
    ansiColor('xterm') {
      sh(script: '''
        export PATH=$PATH:$HOME/.rbenv/bin:$HOME/.rbenv/shims
        echo $PATH
        rbenv global 2.3.1
        gem install bundle
        bundle install
        bundle exec rake spec_clean
        bundle exec rake spec
      ''')
    }
  }
}

def windows(){
  withEnv(['MODULE_WORKING_DIR=C:/tmp']) {
    ansiColor('xterm') {
      dir("C:/cr"){
        unstash "cr-mod"
        sh(script: 'tar -zxvf control-repo.tar.gz')
        sh(script: '''
          bundle install
          bundle exec rake spec_clean
          bundle exec rake spec
        ''')
      }
    }
  }
}

def runSpecTests(def platform){
  node('tse-slave-' + platform) {
    sshagent (credentials: ['jenkins-seteam-ssh']) {
      "$platform"()
    }
  }
}
