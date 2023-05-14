package main

# Do Not store secrets in ENV variables
secrets_env = [
    "passwd",
    "password",
    "pass",
    "secret",
    "key",
    "access",
    "api_key",
    "apikey",
    "token",
    "tkn"
]

deny[msg] {    
    input[index].Cmd == "env"
    val := input[index].Value
    contains(lower(val[_]), secrets_env[_])
    msg = sprintf("Line %d: Potential secret in ENV key found: %s", [index, val])
}

# Only use trusted base images
#deny[msg] {
#    input[index].Cmd == "from"
#    val := split(input[index].Value[0], "/")
#    count(val) > 1
#    msg = sprintf("Line %d: use a trusted base image", [index])
#}

# Do not use 'latest' tag for base imagedeny[msg] {
deny[msg] {
    input[index].Cmd == "from"
    val := split(input[index].Value[0], ":")
    contains(lower(val[index]), "latest")
    msg = sprintf("Line %d: do not use 'latest' tag for base images", [index])
}

# Avoid curl bashing
deny[msg] {
    input[index].Cmd == "run"
    val := concat(" ", input[index].Value)
    matches := regex.find_n("(curl|wget)[^|^>]*[|>]", lower(val), -1)
    count(matches) > 0
    msg = sprintf("Line %d: Avoid curl bashing", [index])
}

# Do not upgrade your system packages
warn[msg] {
    input[index].Cmd == "run"
    val := concat(" ", input[index].Value)
    matches := regex.match(".*?(apk|yum|dnf|apt|pip).+?(install|[dist-|check-|group]?up[grade|date]).*", lower(val))
    matches == true
    msg = sprintf("Line: %d: Do not upgrade your system packages: %s", [index, val])
}

# Do not use ADD if possible
deny[msg] {
    input[index].Cmd == "add"
    msg = sprintf("Line %d: Use COPY instead of ADD", [index])
}

# Any user...
any_user {
    input[index].Cmd == "user"
 }

deny[msg] {
    not any_user
    msg = "Do not run as root, use USER instead"
}

# ... but do not root
forbidden_users = [
    "root",
    "toor",
    "0"
]

deny[msg] {
    command := "user"
    users := [name | input[index].Cmd == "user"; name := input[index].Value]
    lastuser := users[count(users)-1]
    contains(lower(lastuser[_]), forbidden_users[_])
    msg = sprintf("Line %d: Last USER directive (USER %s) is forbidden", [index, lastuser])
}

# Do not sudo
deny[msg] {
    input[index].Cmd == "run"
    val := concat(" ", input[index].Value)
    contains(lower(val), "sudo")
    msg = sprintf("Line %d: Do not use 'sudo' command", [index])
}

# Use multi-stage builds
default multi_stage = false
multi_stage = true {
    input[index].Cmd == "copy"
    val := concat(" ", input[index].Flags)
    contains(lower(val), "--from=")
}
deny[msg] {
    multi_stage == false
    msg = sprintf("You COPY, but do not appear to use multi-stage builds...", [])
}