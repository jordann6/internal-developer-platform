###############################################################################
# Dev Environment
# Wires all modules together. Run terraform commands from this directory.
###############################################################################

locals {
  tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
    Owner       = "jordan"
  }
}

# --- Secrets (KMS + DB credentials) ---
module "secrets" {
  source = "../../modules/secrets"

  project_name = var.project_name
  tags         = local.tags
}

# --- Networking ---
module "networking" {
  source = "../../modules/networking"

  project_name = var.project_name
  kms_key_arn  = module.secrets.kms_key_arn
  tags         = local.tags
}

# --- Database ---
module "database" {
  source = "../../modules/database"

  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  vpc_cidr_block     = module.networking.vpc_cidr_block
  private_subnet_ids = module.networking.private_subnet_ids
  kms_key_arn        = module.secrets.kms_key_arn
  db_username        = "backstage"
  db_password        = jsondecode(data.aws_secretsmanager_secret_version.db_creds.secret_string)["password"]
  db_name            = "backstage"
  tags               = local.tags
}

data "aws_secretsmanager_secret_version" "db_creds" {
  secret_id  = module.secrets.db_credentials_secret_arn
  depends_on = [module.secrets]
}

# --- ECR ---
module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  kms_key_arn  = module.secrets.kms_key_arn
  tags         = local.tags
}

# --- ALB ---
module "alb" {
  source = "../../modules/alb"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  vpc_cidr_block    = module.networking.vpc_cidr_block
  public_subnet_ids = module.networking.public_subnet_ids
  kms_key_arn       = module.secrets.kms_key_arn
  tags              = local.tags
}

# --- ECS ---
module "ecs" {
  source = "../../modules/ecs"

  project_name              = var.project_name
  vpc_id                    = module.networking.vpc_id
  private_subnet_ids        = module.networking.private_subnet_ids
  ecr_repository_url        = module.ecr.repository_url
  ecr_repository_arn        = module.ecr.repository_arn
  db_credentials_secret_arn = module.secrets.db_credentials_secret_arn
  db_hostname               = module.database.db_hostname
  db_port                   = module.database.db_port
  kms_key_arn               = module.secrets.kms_key_arn
  alb_security_group_id     = module.alb.alb_security_group_id
  alb_dns_name              = module.alb.alb_dns_name
  target_group_arn          = module.alb.target_group_arn
  tags                      = local.tags
}
