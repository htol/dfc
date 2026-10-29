function cxh --description 'Start Codex with the latest available Sol and high reasoning'
    set -l model (command codex debug models | command jq -er '
        [.models[]
         | select(.visibility == "list")
         | select(.slug | test("^gpt-[0-9]+([.][0-9]+)*-sol$"))
         | select(any(.supported_reasoning_levels[]?; .effort == "high"))
         | {slug, version: (.slug | capture("^gpt-(?<v>[0-9]+(?:[.][0-9]+)*)-sol$").v | split(".") | map(tonumber))}
        ] | sort_by(.version) | last | .slug
    ')
    if test -z "$model"
        echo 'cxh: No available Sol model with high reasoning found' >&2
        return 1
    end
    command codex --model $model --config 'model_reasoning_effort="high"' $argv
end
