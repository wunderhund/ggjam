version: 0.1

phases:
  pre_build:
    commands:
      - 
      - cat /etc/*release*
      - apt-get install -y git curl jq
      - npm install -g gatsby-cli
      - gatsby new gatsby-starter-ghost https://github.com/wunderhund/gatsby-starter-ghost.git
      - cd gatsby-starter-ghost && yarn
      - contents="$(jq '.production.apiUrl = "http://${ghost_url}:${ghost_port}"' gatsby-starter-ghost/.ghost.json)" && echo $contents | jq '.' > gatsby-starter-ghost/.ghost.json
      - contents="$(jq '.production.contentApiKey = "${ghost_api_key}"' gatsby-starter-ghost/.ghost.json)" && echo $contents | jq '.' > gatsby-starter-ghost/.ghost.json
      - cat gatsby-starter-ghost/.ghost.json
  build:
    commands:
      - cd gatsby-starter-ghost && gatsby build
      - ls gatsby-starter-ghost

      # - tar -cvf frontend.tar public
  post_build:
    commands:
      - aws s3 sync ./gatsby-starter-ghost/public "s3://${artifacts_bucket}/" --delete --quiet