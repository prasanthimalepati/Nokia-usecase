###Create user with admin access#######

resource "aws_iam_user" "my-test-user" {
  name = "admin"
}

resource "aws_iam_access_key" "my-test-access-key" {
  user = aws_iam_user.my-test-user.name
}

data "aws_iam_policy" "my-test-admin" {
  name = "AdministratorAccess"
}

resource "aws_iam_policy_attachment" "my-test-admin-policy" {
    name = "admin-policy"
    policy_arn = data.aws_iam_policy.my-test-admin.name
}

###Create dev group######


resource "aws_iam_group" "developers" {
  name = "developers"
}

#create user
resource "aws_iam_user" "my-test-dev" {
    name = "dev1"
}

#Add users to group
resource "aws_iam_group_membership" "dev-users" {
    name = "dev-users"
    users = [
        "${aws_iam_user.my-test-dev.name}",
    ]
    group = "${aws_iam_group.developers.name}"
}


resource "aws_iam_user_policy" "my-test-policy" {
  name = "my-policy"
  user = aws_iam_user.my-test-user.name
policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

