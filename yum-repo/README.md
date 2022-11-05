heroku container:login

heroku container:push -a mbp-fedora-repo web
heroku container:release -a mbp-fedora-repo web

heroku ps -a mbp-fedora-repo
heroku logs --tail -a mbp-fedora-repo
heroku container:rm -a mbp-fedora-repo web
