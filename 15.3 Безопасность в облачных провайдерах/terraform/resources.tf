##### GET SERVICEACCOUNT ID #####
locals {
  key = sensitive(jsondecode(file("${path.module}/key.json")))
}

##### CREATE SYMMETRIC KEY #####

resource "yandex_kms_symmetric_key" "key-a" {
  name              = "example-symetric-key"
  description       = "description for key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" // equal to 1 year
}

##### CREATE BUCKET #####

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.yandex_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${local.key.service_account_id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-static-key" {
  service_account_id = "${local.key.service_account_id}"
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "netology" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "netology.bucket"
  acl    = "public-read"

  #server_side_encryption_configuration {
  #  rule {
  #    apply_server_side_encryption_by_default {
  #      kms_master_key_id = yandex_kms_symmetric_key.key-a.id
  #      sse_algorithm     = "aws:kms"
  #    }
  #  }
  #}
} 
##### PUT PICTURE INTO BUCKET #####
resource "yandex_storage_object" "devops_pic" {
  access_key = yandex_iam_service_account_static_access_key.sa-static-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa-static-key.secret_key
  bucket = "netology.bucket"
  key    = "devops"
  source = "../images/devops.png"
  depends_on = [
    yandex_storage_bucket.netology
  ]
}

