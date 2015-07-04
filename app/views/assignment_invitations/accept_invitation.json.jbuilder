message = <<-eos
You are ready to go, if this is your first assignment go ahead
and check your email.
Otherwise head over to <a href="https://github.com/#{@repo_url}">#{@repo_url}</a>
eos

json.message message
