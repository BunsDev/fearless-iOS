@Library('jenkins-library') _

// Job properties
def jobParams = [
  booleanParam(defaultValue: false, description: 'push to the dev profile', name: 'prDeployment'),
]

def appPipline = new org.ios.AppPipeline(
    steps: this, 
    appTests: true,
    appPushNoti: true,
    jobParams: jobParams,
    label: 'mac-ios-agent')
appPipline.runPipeline('fearless')