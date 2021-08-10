#!/bin/bash
    helm upgrade gitlab-runner --set gitlabUrl=https://192.168.178.40/,runnerRegistrationToken=PjNUMwQ3jfBtFPKs6JXF gitlab/gitlab-runner
