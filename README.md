# Tiller

Deploy Trellis, Bedrock and Sage via AWS CodeBuild.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Requirements](#requirements)
- [What's in the box?](#whats-in-the-box)
- [Set Up](#set-up)
  - [GitHub](#github)
  - [Trellis](#trellis)
  - [`buildspec.yml`](#buildspecyml)
  - [AWS CodeBuild](#aws-codebuild)
    - [Docker Image](#docker-image)
    - [Environment Variables](#environment-variables)
      - [`PRIVATE_KEY` & `PRIVATE_KEY_PASSPHRASE`](#private_key--private_key_passphrase)
    - [`SITE_ENV` & `SITE_KEY`](#site_env--site_key)
    - [Examples](#examples)
  - [Docker Image](#docker-image-1)
- [FAQ](#faq)
  - [Is it a must to use all Trellis, Bedrock and Sage?](#is-it-a-must-to-use-all-trellis-bedrock-and-sage)
  - [Is it a must to use AWS CodeBuild?](#is-it-a-must-to-use-aws-codebuild)
  - [Is it a must to use GitHub?](#is-it-a-must-to-use-github)
  - [Can I use multiple SSH key pairs?](#can-i-use-multiple-ssh-key-pairs)
  - [What does S3 bucket cache?](#what-does-s3-bucket-cache)
- [Author Information](#author-information)
- [Feedback](#feedback)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Requirements

- Trellis [b556ccd](https://github.com/roots/trellis/commit/b556ccdb2b3183eba4a9530b206a402422deeca3) or later
- (Optional) Bedrock [ef090b6](https://github.com/roots/bedrock/commit/ef090b63ca0b772390a1db03cc7c118af20e8733) or later
- (Optional) Sage [9.0.1](https://github.com/roots/sage/releases/tag/9.0.1) or later
- (Optional) AWS [CodeBuild](https://aws.amazon.com/codebuild/)

## What's in the box?

- A docker image to run deployment
- [buildspec.yml](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html) examples

## Set Up

You need a robot user for deployment. In this example, we will use a GitHub machine user account as our robot. For simplicity, this robot uses the same SSH key pair to access both GitHub private repos and the web server.

### GitHub

1. Sign up a machine user on GitHub
1. Grant `mybot` **read** access to all necessary private repos
1. Generate a SSH key pair
    - `ssh-keygen -t ed25519 -C "mybot-$(date)"`
    - It must use a passphrase
1. [Upload the public key to Github](https://help.github.com/articles/adding-a-new-ssh-key-to-your-github-account/)

### Trellis

1. Add the SSH key to web server
    ```yml
    # group_vars/<env>/users.yml
    users:
      - name: "{{ web_user }}"
        groups:
          - "{{ web_group }}"
        keys:
          - https://github.com/human.keys
          - https://github.com/mybot.keys # <-- This line
      - name: "{{ admin_user }}"
        groups:
          - sudo
        keys:
          - https://github.com/human.keys
    ```
1. Re-provision
    `ansible-playbook server.yml -e env=<env> --tags users`

### `buildspec.yml`

Tiller comes with 2 different `buildspec.yml` examples. They are expecting different Trellis and Bedrock structures.

Use `buildspec.yml` if your directory structure follow [the official documents](https://roots.io/trellis/docs/installing-trellis/#create-a-project):
```
example.com/      # → Root folder for the project
├── .git/         # → Only one git repo
├── trellis/      # → Your clone of roots/trellis, directory name must be `trellis`
└── site/         # → A Bedrock-based WordPress site, directory name doesn't matter
```

[`buildspec.itineris.yml`](./buildspec.itineris.yml) do extra steps for itineris-specific project setup.

At [Itineris](https://www.itineris.co.uk/), we use a opinionated project structure:
- separate Trellis and Bedrock as 2 different git repo
- name the Bedrock-based WordPress site directory more creatively, i.e: `bedrock`
- extra deploy command parameter for our SSH bastion host, i.e: `-e bastion_user=$BASTION_USER`

```
example.com/      # → Root folder for the project
├── bedrock/      # → A Bedrock-based WordPress site, directory name must be `bedrock`
│   └── .git/     # Bedrock git repo
└── trellis/      # → Clone of roots/trellis, directory name must be `trellis`
    └── .git/     # Trellis git repo
```

See: [roots/trellis#883 (comment)](https://github.com/roots/trellis/issues/883#issuecomment-329052189)

To install:
- Option A: Use the `buildspec.yml` in the source code root directory
    1. Copy and commit the `.yml` file to project root
    1. Review the `.yml` file, change if necessary
    1. Enter the `.yml` file name on AWS web console

- Option B: Insert build commands via AWS web console
    1. Copy and paste the `.yml` file to AWS web console
    1. Review the commands, change if needed

### AWS CodeBuild

#### Docker Image

Use [`itinerisltd/tiller`](https://hub.docker.com/r/itinerisltd/tiller/). See [below](#docker-image-1).

#### Environment Variables

| Name                  | Value                      | Type            |                                |
| --------------------- | -------------------------- | --------------- | ------------------------------ |
| PRIVATE_KEY           | /ssm/the-private-key       | Parameter Store |                                |
| PRIVATE_KEY_PASSPHRASE | /ssm/the-passphrase         | Parameter Store |                                |
| SITE_ENV              | production                 | Plaintext       |                                |
| SITE_KEY              | example.com                | Plaintext       |                                |
| BASTION_USER          | mybot                      | Plaintext       | `buildspec.itineris.yml ` only |
| TRELLIS_REPO          | git@github.com:xxx/yyy.git | Plaintext       | `buildspec.itineris.yml ` only |

##### `PRIVATE_KEY` & `PRIVATE_KEY_PASSPHRASE`

Encrypt `PRIVATE_KEY` and `PRIVATE_KEY_PASSPHRASE` with [AWS Systems Manager Parameter Store and AWS KMS](https://docs.aws.amazon.com/kms/latest/developerguide/services-parameter-store.html). **Never save them in plaintext!**


`PRIVATE_KEY` needs line break characters(`\n`) For example:
```bash
➜ cat ~/.ssh/mybot
-----BEGIN OPENSSH PRIVATE KEY-----
aaa
bbb
ccc
-----END OPENSSH PRIVATE KEY-----
```

Then, save `PRIVATE_KEY` as:
```
-----BEGIN OPENSSH PRIVATE KEY-----\naaa\nbbb\nccc\n-----END OPENSSH PRIVATE KEY-----
```

#### `SITE_ENV` & `SITE_KEY`

They are used to build the final deploy command:
```bash
# ansible-playbook deploy.yml -e env=$SITE_ENV -e site=$SITE_KEY -vvvv
➜ ansible-playbook deploy.yml -e env=production -e site=example.com -vvvv
```

#### Examples

![](./buildspec-yml.png)


![](./buildspec-itineris-yml.png)

### Docker Image

Tiller comes with a [docker image](https://hub.docker.com/r/itinerisltd/tiller/) to run Trellis deployment:
- Ubuntu 16.04
- libpng-dev
- libpng16-16
- NodeJS v8
- Yarn
- Anisble
- Git
- [expect-ssh-add.sh](./expect-ssh-add.sh)

This is sufficient for deploying a default Trellis, Bedrock and Sage project. You can build your own docker image if necessary:

```bash
# Modify `Dockerfile`

# Build the image without caches
# Not using caches because we want latest packages to be installed
➜ docker build --no-cache --compress --tag tiller .

# Tag the image
➜ docker tag tiller itinerisltd/tiller:2018.5.18.2
➜ docker tag tiller itinerisltd/tiller:latest

# Push the image
➜ docker push itinerisltd/tiller:2018.5.18.2
➜ docker push itinerisltd/tiller:latest
```

## FAQ

### Is it a must to use all Trellis, Bedrock and Sage?

No, you don't need all of them. Only Trellis is required.

### Is it a must to use AWS CodeBuild?

No. You can use the docker image without AWS CodeBuild.

### Is it a must to use GitHub?

No.

### Can I use multiple SSH key pairs?

Yes.

```yaml
phases:
  pre_build:
    commands:
      - echo "$PRIVATE_KEY" > $HOME/.ssh/id_rsa
      - echo "$PRIVATE_KEY_SECOND" > $HOME/.ssh/id_rsa_second
      - chmod 600 $HOME/.ssh/id_rsa*
      - expect-ssh-add.sh id_rsa $PRIVATE_KEY_PASSPHRASE
      - expect-ssh-add.sh id_rsa_second $PRIVATE_KEY_PASSPHRASE_SECOND
```

### What does S3 bucket cache?

By default only yarn packages are cached. It speeds up the build by 20~60 seconds.
This is optional and you can add more `cache.paths`.

## Author Information

[Tiller](https://github.com/ItinerisLtd/tiller) is a [Itineris Limited](https://www.itineris.co.uk/) project created by [Tang Rufus](https://typist.tech).

Special thanks to [the Roots team](https://roots.io/about/) whose [Trellis](https://github.com/roots/trellis) make this project possible.

Full list of contributors can be found [here](https://github.com/ItinerisLtd/tiller/graphs/contributors).

## Feedback

**Please provide feedback!** We want to make this library useful in as many projects as possible.
Please submit an [issue](https://github.com/ItinerisLtd/tiller/issues/new) and point out what you do and don't like, or fork the project and make suggestions.
**No issue is too small.**
