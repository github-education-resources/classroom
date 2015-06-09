# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150608135401) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "group_assignment_invitations", force: :cascade do |t|
    t.string   "key",                 null: false
    t.integer  "group_assignment_id"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
  end

  add_index "group_assignment_invitations", ["key"], name: "group_assg_invitation_key", unique: true, using: :btree

  create_table "group_assignment_repos", force: :cascade do |t|
    t.integer  "github_repo_id",      null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.integer  "group_assignment_id"
  end

  add_index "group_assignment_repos", ["github_repo_id"], name: "index_group_assignment_repos_on_github_repo_id", unique: true, using: :btree
  add_index "group_assignment_repos", ["group_assignment_id"], name: "index_group_assignment_repos_on_group_assignment_id", using: :btree

  create_table "group_assignments", force: :cascade do |t|
    t.string   "title",           null: false
    t.integer  "organization_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "group_assignments", ["organization_id"], name: "index_group_assignments_on_organization_id", using: :btree

  create_table "groupings", force: :cascade do |t|
    t.string   "title",           null: false
    t.integer  "organization_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "groupings", ["organization_id"], name: "index_groupings_on_organization_id", using: :btree

  create_table "groups", force: :cascade do |t|
    t.integer  "github_team_id", null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.integer  "grouping_id"
  end

  add_index "groups", ["github_team_id"], name: "index_groups_on_github_team_id", unique: true, using: :btree
  add_index "groups", ["grouping_id"], name: "index_groups_on_grouping_id", using: :btree

  create_table "individual_assignment_invitations", force: :cascade do |t|
    t.string   "key",                      null: false
    t.integer  "individual_assignment_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
  end

  add_index "individual_assignment_invitations", ["key"], name: "indv_assg_invitation_key", unique: true, using: :btree

  create_table "individual_assignment_repos", force: :cascade do |t|
    t.integer  "github_repo_id",           null: false
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "individual_assignment_id"
  end

  add_index "individual_assignment_repos", ["github_repo_id"], name: "index_individual_assignment_repos_on_github_repo_id", unique: true, using: :btree
  add_index "individual_assignment_repos", ["individual_assignment_id"], name: "index_individual_assignment_repos_on_individual_assignment_id", using: :btree

  create_table "individual_assignments", force: :cascade do |t|
    t.string   "title",           null: false
    t.integer  "organization_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "individual_assignments", ["organization_id"], name: "index_individual_assignments_on_organization_id", using: :btree

  create_table "organizations", force: :cascade do |t|
    t.integer  "github_id",  null: false
    t.string   "title",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "organizations", ["github_id"], name: "index_organizations_on_github_id", unique: true, using: :btree
  add_index "organizations", ["title"], name: "index_organizations_on_title", unique: true, using: :btree

  create_table "organizations_users", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
  end

  add_index "organizations_users", ["organization_id"], name: "index_organizations_users_on_organization_id", using: :btree
  add_index "organizations_users", ["user_id"], name: "index_organizations_users_on_user_id", using: :btree

  create_table "repo_accesses", force: :cascade do |t|
    t.integer  "github_team_id",  null: false
    t.integer  "organization_id"
    t.integer  "user_id"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
  end

  add_index "repo_accesses", ["github_team_id"], name: "index_repo_accesses_on_github_team_id", unique: true, using: :btree
  add_index "repo_accesses", ["organization_id"], name: "index_repo_accesses_on_organization_id", using: :btree
  add_index "repo_accesses", ["user_id"], name: "index_repo_accesses_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uid",        null: false
    t.string   "token",      null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "users", ["token"], name: "index_users_on_token", unique: true, using: :btree
  add_index "users", ["uid"], name: "index_users_on_uid", unique: true, using: :btree

end
