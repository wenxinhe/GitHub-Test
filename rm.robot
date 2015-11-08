*** Settings ***
Documentation	Test suite for working with GitHub.
...

Resource		github-keywords.robot

Test Setup		Create GitHub Session
Test Teardown	Tear Down

*** Test Cases ***
Git rm
	Given a remote repo "${YOUR_GITHUB_REPO}" on Github
	And there is a file "to-be-removed.md"
	And a local clone repo "${YOUR_GITHUB_REPO}-local"
	When I remove the local "to-be-removed.md" and push changes
	Then remote should have removed the same file

*** Keywords ***
a remote repo "${repo}" on Github
	Set Test Variable	${remote-repo}	${repo}
	Should Exist Remote Repo	${remote-repo}

there is a file "${file}"
	Set Test Variable	${path}	${file}
	Set Test Variable	${file-content}	\# To Be Removed
	Create File on Remote Repo	${remote-repo}	${path}	${file-content}

a local clone repo "${repo}"
	Set Test Variable	${local-repo}	${repo}
	Clone Local Repo	${remote-repo}	${local-repo}

I remove the local "${file}" and push changes
	Remove Local File and Commit	${local-repo}	${path}
	Push Local Changes to Remote	${local-repo}

remote should have removed the same file
	Should Not Exist Remote File	${remote-repo}	${path}

Tear Down
	Remove Local Repo	${local-repo}
	Delete All Sessions