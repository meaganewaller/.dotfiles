function grf --description "Git reflog CSV output piped to tw"
  begin
    echo "Commit"(printf '\x1e')"Date"(printf '\x1e')"Time"(printf '\x1e')"Command"(printf '\x1e')"Details"(printf '\x1e')"Comment"(printf '\x1e')"Branches"(printf '\x1e')"Tags"
    git --no-pager reflog --pretty='format:%h%x1e%gD%x1e%gs%x1e%d' --date=iso --decorate=short -- $argv | node -e '
      let data = "";
      process.stdin.on("data", (chunk) => data += chunk);
      process.stdin.on("end", () => {
        const lines = data.split("\n");
        for (const line of lines) {
          if (!line.trim()) {
            continue
          }
          const parts = line.split("\x1e");
          if (parts.length < 3) {
            continue;
          }

          const [commit, gd, gs, decorationsRaw = ""] = parts;
          const [date, time] = gd.match(/^HEAD@{(.*)}$/)[1].split(" ");
          const [command, details = "", comment] = gs.match(/^([^\s:]+)(?:\s+\(([^)]+)\))?\s*:\s+(.+)$/).slice(1);
          const decorations = decorationsRaw.replace(" (", "").replace(")", "");
          const branches = decorations.split(",").filter((d) => !d.startsWith("tag:")).join(",");
          const tags = decorations.split(",").filter((d) => d.startsWith("tag:")).map((t) => t.replace("tag: ", "")).join(",");

          console.log([commit, date, time, command, details, comment, branches, tags].join("\x1e"));
        }
      });
    '
  end | tw --separator (printf '\x1e') --quote-char (printf '\x1f')
end
