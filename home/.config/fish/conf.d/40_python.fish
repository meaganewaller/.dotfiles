# function __setup_python_env --description "Auto venv + mise hook for Python projects" --on-event fish_prompt
#     status is-interactive || return

#     if test -f pyproject.toml; or test -f requirements.txt
#         if not test -d .venv
#             type -q uv; and command uv venv
#         end
#     end

#     if test -d .venv; and not test -f uv.lock
#         printf 'version = 1\nrequires-python = ">=3.10"\n' > uv.lock
#     end

#     set -l venv_bin "$PWD/.venv/bin"
#     if test -f uv.lock; and not contains -- $venv_bin (string split : -- $PATH)
#         type -q mise; and mise hook-env -s fish | source
#     end
# end
