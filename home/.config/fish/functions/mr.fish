function mr --description "List merge requests in CSV format"
  set -l repo (git remote get-url origin | sed 's/.*[:/]\([^/]*\)\/\(.*\)\.git$/\1\/\2/')
  begin
    echo '"ID","Title","Branch","Author","Approves","Created","Updated"'
    glab mr list --repo "$repo" -F json | jq -r '.[] | [.iid, .title, .source_branch, .author.name, (.approvals.approved_by | length), .created_at, .updated_at] | @csv'
  end | tw
end

complete -c mr -f
