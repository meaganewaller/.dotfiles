function pr --description "List pull requests in CSV format"
  set -l repo (git remote get-url origin | sed 's/.*[:/]\([^/]*\)\/\(.*\)\.git$/\1\/\2/')
  begin
    echo '"ID","Title","Branch","Author","Commits","Approves","Created","Updated"'
    gh pr list --repo "$repo" --json number,title,headRefName,author,commits,reviews,createdAt,updatedAt | jq -r '.[] | [.number, .title, .headRefName, .author.login, (.commits | length), ([.reviews[] | select(.state=="APPROVED")] | length), .createdAt, .updatedAt] | @csv'
  end | tw
end

complete -c pr -f
