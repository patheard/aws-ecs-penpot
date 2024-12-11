terraform {
  source = "../..//aws"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  penpot_database_instance_class  = "db.serverless"
  penpot_database_instances_count = 1
  penpot_database_min_capacity    = 1
  penpot_database_max_capacity    = 4
}
