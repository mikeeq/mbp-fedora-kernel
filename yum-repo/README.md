heroku container:login

heroku container:push -a fedora-mbp-repo web
heroku container:release -a fedora-mbp-repo web

heroku ps -a fedora-mbp-repo
heroku logs --tail -a fedora-mbp-repo
heroku container:rm -a fedora-mbp-repo web
