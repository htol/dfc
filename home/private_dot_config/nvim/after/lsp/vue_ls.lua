return {
  filetypes = { 'vue' },
  init_options = {
    typescript = {
      tsdk = vim.fn.stdpath("data") .. "/mason/packages/vue-language-server/node_modules/typescript/lib",
    },
  },
}
