return{
    -- Little know features:
    --   :SSave
    --   :SLoad
    --       These are wrappers for mksession that work great. I never have to use
    --       mksession anymore or worry about where things are saved / loaded from.
    {
        "mhinz/vim-startify",
        cmd = { "SLoad", "SSave" },
        config = function()
            vim.g.startify_disable_at_vimenter = true
        end,
    },
}
