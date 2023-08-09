local perforce = require("perforce")

vim.api.nvim_create_user_command("P4Attach",
  perforce.attach,
  {
    desc = "P4 buffer attach",
  })

vim.api.nvim_create_user_command("P4Detach",
  perforce.detach,
  {
    desc = "P4 buffer detach",
  })

vim.api.nvim_create_user_command("P4DetachAll",
  perforce.detach_all,
  {
    desc = "P4 buffer detach all",
  })

vim.api.nvim_create_user_command(
  "P4Add",
  function(cmd)
    perforce.add()
  end,
  {
    bang = true,
    desc = "P4 file add"
  }
)

vim.api.nvim_create_user_command(
  "P4Delete",
  function(cmd)
    perforce.delete()
  end,
  {
    bang = true,
    desc = "P4 file delete"
  }
)

vim.api.nvim_create_user_command(
  "P4Edit",
  function(cmd)
    local opts = {
      force = cmd.bang == true,
    }
    -- TODO: support user providing an extra file path
    -- if #cmd.fargs > 0 then
    --   opts.file = cmd.fargs[1]
    -- end
    perforce.edit(opts)
  end,
  {
    nargs = "?",
    bang = true,
    desc = "P4 file edit"
  }
)

vim.api.nvim_create_user_command(
  "P4Revert",
  function(cmd)
    local opts = {
      force = cmd.bang == true,
    }
    perforce.revert(opts)
  end,
  {
    bang = true,
    desc = "P4 file revert"
  }
)

-- P4Filelog
-- P4Annotate

-- P4Diff <target>
-- P4PreviewHunk
-- P4PreviewHunkInline
-- P4NextHunk
-- P4PrevHunk
-- P4SelectHunk
