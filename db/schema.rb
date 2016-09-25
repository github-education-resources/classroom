# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160621020153) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignment_invitations", force: :cascade do |t|
    t.string   "key",           null: false
    t.integer  "assignment_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.datetime "deleted_at"
    t.index ["assignment_id"], name: "index_assignment_invitations_on_assignment_id", using: :btree
    t.index ["deleted_at"], name: "index_assignment_invitations_on_deleted_at", using: :btree
    t.index ["key"], name: "index_assignment_invitations_on_key", unique: true, using: :btree
  end

  create_table "assignment_repos", force: :cascade do |t|
    t.integer  "github_repo_id", null: false
    t.integer  "repo_access_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.index ["assignment_id"], name: "index_assignment_repos_on_assignment_id", using: :btree
    t.index ["github_repo_id"], name: "index_assignment_repos_on_github_repo_id", unique: true, using: :btree
    t.index ["repo_access_id"], name: "index_assignment_repos_on_repo_access_id", using: :btree
    t.index ["user_id"], name: "index_assignment_repos_on_user_id", using: :btree
  end

  create_table "assignments", force: :cascade do |t|
    t.boolean  "public_repo",                default: true
    t.string   "title",                                      null: false
    t.integer  "organization_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "starter_code_repo_id"
    t.integer  "creator_id"
    t.datetime "deleted_at"
    t.string   "slug",                                       null: false
    t.integer  "student_identifier_type_id"
    t.boolean  "students_are_repo_admins",   default: false, null: false
    t.index ["deleted_at"], name: "index_assignments_on_deleted_at", using: :btree
    t.index ["organization_id"], name: "index_assignments_on_organization_id", using: :btree
    t.index ["slug"], name: "index_assignments_on_slug", using: :btree
  end

  create_table "group_assignment_invitations", force: :cascade do |t|
    t.string   "key",                 null: false
    t.integer  "group_assignment_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_group_assignment_invitations_on_deleted_at", using: :btree
    t.index ["group_assignment_id"], name: "index_group_assignment_invitations_on_group_assignment_id", using: :btree
    t.index ["key"], name: "index_group_assignment_invitations_on_key", unique: true, using: :btree
  end

  create_table "group_assignment_repos", force: :cascade do |t|
    t.integer  "github_repo_id",      null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "group_assignment_id"
    t.integer  "group_id",            null: false
    t.index ["github_repo_id"], name: "index_group_assignment_repos_on_github_repo_id", unique: true, using: :btree
    t.index ["group_assignment_id"], name: "index_group_assignment_repos_on_group_assignment_id", using: :btree
  end

  create_table "group_assignments", force: :cascade do |t|
    t.boolean  "public_repo",                default: true
    t.string   "title",                                      null: false
    t.integer  "grouping_id"
    t.integer  "organization_id"
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
    t.integer  "starter_code_repo_id"
    t.integer  "creator_id"
    t.datetime "deleted_at"
    t.string   "slug",                                       null: false
    t.integer  "max_members"
    t.integer  "student_identifier_type_id"
    t.boolean  "students_are_repo_admins",   default: false, null: false
    t.index ["deleted_at"], name: "index_group_assignments_on_deleted_at", using: :btree
    t.index ["organization_id"], name: "index_group_assignments_on_organization_id", using: :btree
    t.index ["slug"], name: "index_group_assignments_on_slug", using: :btree
  end

  create_table "groupings", force: :cascade do |t|
    t.string   "title",           null: false
    t.integer  "organization_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "slug",            null: false
    t.index ["organization_id"], name: "index_groupings_on_organization_id", using: :btree
  end

  create_table "groups", force: :cascade do |t|
    t.integer  "github_team_id", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "grouping_id"
    t.string   "title",          null: false
    t.string   "slug",           null: false
    t.index ["github_team_id"], name: "index_groups_on_github_team_id", unique: true, using: :btree
    t.index ["grouping_id"], name: "index_groups_on_grouping_id", using: :btree
  end

  create_table "groups_repo_accesses", id: false, force: :cascade do |t|
    t.integer "group_id"
    t.integer "repo_access_id"
    t.index ["group_id"], name: "index_groups_repo_accesses_on_group_id", using: :btree
    t.index ["repo_access_id"], name: "index_groups_repo_accesses_on_repo_access_id", using: :btree
  end

  create_table "organizations", force: :cascade do |t|
    t.integer  "github_id",                         null: false
    t.string   "title",                             null: false
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.datetime "deleted_at"
    t.string   "slug",                              null: false
    t.string   "webhook_id"
    t.boolean  "is_webhook_active", default: false
    t.index ["deleted_at"], name: "index_organizations_on_deleted_at", using: :btree
    t.index ["github_id"], name: "index_organizations_on_github_id", unique: true, using: :btree
    t.index ["slug"], name: "index_organizations_on_slug", using: :btree
  end

  create_table "organizations_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_organizations_users_on_organization_id", using: :btree
    t.index ["user_id"], name: "index_organizations_users_on_user_id", using: :btree
  end

  create_table "repo_accesses", force: :cascade do |t|
    t.integer  "github_team_id"
    t.integer  "organization_id"
    t.integer  "user_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.index ["github_team_id"], name: "index_repo_accesses_on_github_team_id", unique: true, using: :btree
    t.index ["organization_id"], name: "index_repo_accesses_on_organization_id", using: :btree
    t.index ["user_id"], name: "index_repo_accesses_on_user_id", using: :btree
  end

  create_table "student_identifier_types", force: :cascade do |t|
    t.integer  "organization_id"
    t.string   "name",            null: false
    t.string   "description",     null: false
    t.integer  "content_type",    null: false
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.datetime "deleted_at"
    t.index ["organization_id"], name: "index_student_identifier_types_on_organization_id", using: :btree
  end

  create_table "student_identifiers", force: :cascade do |t|
    t.integer  "organization_id"
    t.integer  "user_id"
    t.integer  "student_identifier_type_id"
    t.string   "value",                      null: false
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.datetime "deleted_at"
    t.index ["organization_id"], name: "index_student_identifiers_on_organization_id", using: :btree
    t.index ["student_identifier_type_id"], name: "index_student_identifiers_on_student_identifier_type_id", using: :btree
    t.index ["user_id"], name: "index_student_identifiers_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.integer  "uid",                            null: false
    t.string   "token",                          null: false
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "site_admin",     default: false
    t.datetime "last_active_at",                 null: false
    t.index ["token"], name: "index_users_on_token", unique: true, using: :btree
    t.index ["uid"], name: "index_users_on_uid", unique: true, using: :btree
  end

end
