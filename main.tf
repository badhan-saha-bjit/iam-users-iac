data "http" "google_sheet_csv" {
  url = "https://docs.google.com/spreadsheets/d/${var.spreadsheet_id}/export?format=csv"
}

locals {
  extracted_iam_user_names = split("\r\n", data.http.google_sheet_csv.response_body)
  iam_user_names           = [for username in local.extracted_iam_user_names : username if can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", username))]
}


resource "aws_iam_group" "group" {
  name = "bjit-academy-trainees"
}

resource "aws_iam_user" "iam_user_names" {
  for_each      = { for row in local.iam_user_names : row => row }
  name          = each.key
  force_destroy = true
}

resource "aws_iam_group_membership" "group_membership" {
  name  = "group_membership"
  group = aws_iam_group.group.name
  users = [for user in aws_iam_user.iam_user_names : user.name]
}

resource "aws_iam_group_policy_attachment" "group_policies" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess",
    "arn:aws:iam::aws:policy/IAMUserChangePassword"
  ])

  group      = aws_iam_group.group.name
  policy_arn = each.value
}



resource "aws_iam_user_login_profile" "profiles" {
  for_each                = aws_iam_user.iam_user_names
  user                    = each.key
  password_reset_required = true
}
output "passwords" {
  value     = { for username, profile in aws_iam_user_login_profile.profiles : username => profile.encrypted_password }
  sensitive = false
}



resource "local_file" "passwords_file" {
  content = join("\n", [
    for username, profile in aws_iam_user_login_profile.profiles :
    "${username}: ${profile.password}"
  ])
  filename = "passwords.txt"

  depends_on = [aws_iam_user_login_profile.profiles]
}

/*
resource "null_resource" "delete_passwords_file" {
  provisioner "local-exec" {
    command = "rm -f passwords.txt"
  }
  triggers = {
    # always_run = "${timestamp()}"
    run_on_destroy = true
  }

  depends_on = [local_file.passwords_file]
}


resource "restapi_object" "google_sheet_update" {
  # provider = restapi.restapi_headers
  path     = "/v4/spreadsheets/${var.spreadsheet_id}/values/{Usernames!B1:B40}"
  data = jsonencode({
    range  = "Usernames!B1:B${length(local.iam_user_names)}"
    values = local.iam_user_names
  })

  depends_on = [aws_iam_user.iam_user_names]
}

*/