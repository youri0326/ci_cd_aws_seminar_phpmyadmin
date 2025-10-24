#!/bin/bash
# ====================================
# AWS CI/CD 環境構築スクリプト
# PHP / phpMyAdmin Blue-Green構成
# ====================================

export AWS_REGION=ap-northeast-1

# ------------------------------
# phpMyAdmin セットアップ
# ------------------------------
echo "=== phpMyAdmin セットアップ開始 ==="

# ディレクトリ作成
mkdir -p /mnt/c/ci_cd_aws_seminar_phpmyadmin
cd /mnt/c/ci_cd_aws_seminar_phpmyadmin

# GitHub 初期化
echo "# ci_cd_aws_seminar_phpmyadmin" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote set-url origin git@github.com:youri0326/ci_cd_aws_seminar_phpmyadmin.git
git push -u origin main

# ------------------------------
# 既存ファイルをコピー
# ------------------------------
cp -r /mnt/c/ci_cd_aws_seminar/phpmyadmin-cicd/* /mnt/c/ci_cd_aws_seminar_phpmyadmin

# ------------------------------
# ファイルをGitにコミット・プッシュ
# ------------------------------
git add .
git commit -m "Add initial project files for CI/CD setup"
git push origin main

# CodeBuild プロジェクト作成
aws codebuild create-project \
  --name phpmyadmin-build-yoshiike-20251019 \
  --source type=CODEPIPELINE,buildspec=CodeBuild/buildspec-phpmyadmin.yml \
  --artifacts type=CODEPIPELINE \
  --environment type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:5.0 \
  --service-role arn:aws:iam::963220189927:role/CodeBuildServiceRole-yoshiike-20251019 \
  --region ${AWS_REGION}

# CodePipeline 作成
aws codepipeline create-pipeline \
  --cli-input-json file://CodePipeline/pipeline-phpmyadmin-rolling.json \
  --region ${AWS_REGION}

# ------------------------------
# PHP セットアップ
# ------------------------------
echo "=== PHP セットアップ開始 ==="

# ディレクトリ作成
mkdir -p /mnt/c/ci_cd_aws_seminar_php
cd /mnt/c/ci_cd_aws_seminar_php

# GitHub 初期化
echo "# ci_cd_aws_seminar_php" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin https://github.com/youri0326/ci_cd_aws_seminar_php.git
git push -u origin main

# CodeBuild プロジェクト作成
aws codebuild create-project \
  --name php-build-yoshiike-20251019 \
  --source type=CODEPIPELINE,buildspec=CodeBuild/buildspec-php.yml \
  --artifacts type=CODEPIPELINE \
  --environment type=LINUX_CONTAINER,computeType=BUILD_GENERAL1_SMALL,image=aws/codebuild/standard:5.0 \
  --service-role arn:aws:iam::963220189927:role/CodeBuildServiceRole-yoshiike-20251019 \
  --region ${AWS_REGION}

# CodeDeploy アプリ作成
aws deploy create-application \
  --application-name cicd-aws-codedeploy-php-yoshiike-20251019 \
  --compute-platform ECS \
  --region ${AWS_REGION}

# CodeDeploy デプロイグループ作成
aws deploy create-deployment-group \
  --application-name cicd-aws-codedeploy-php-yoshiike-20251019 \
  --deployment-group-name cicd-aws-codedeploy-php-group \
  --service-role-arn arn:aws:iam::963220189927:role/CodeDeployServiceRole-yoshiike-20251019 \
  --deployment-style deploymentType=BLUE_GREEN,deploymentOption=WITH_TRAFFIC_CONTROL \
  --target-group-pair-info file://CodeDeploy/tg-pair.json \
  --ecs-services clusterName=ecs-cluster-yoshiike-20251019,serviceName=php-service-yoshiike-20251019 \
  --region ${AWS_REGION}

# CodePipeline 作成（Blue/Green）
aws codepipeline create-pipeline \
  --cli-input-json file://CodePipeline/pipeline-php-bluegreen.json \
  --region ${AWS_REGION}

echo "=== すべてのセットアップが完了しました ==="
