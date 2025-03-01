"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[522],{3415:(e,n,r)=>{r.r(n),r.d(n,{assets:()=>a,contentTitle:()=>t,default:()=>h,frontMatter:()=>o,metadata:()=>s,toc:()=>l});const s=JSON.parse('{"id":"Addons","title":"Addons","description":"Want to create your own addon for GAdmin? Here are some requirements you must follow:","source":"@site/docs/Addons.md","sourceDirName":".","slug":"/Addons","permalink":"/GAdminV2/docs/Addons","draft":false,"unlisted":false,"editUrl":"https://github.com/gdr1461/GAdminV2/edit/main/docs/Addons.md","tags":[],"version":"current","sidebarPosition":4,"frontMatter":{"sidebar_position":4},"sidebar":"defaultSidebar","previous":{"title":"Migrate","permalink":"/GAdminV2/docs/Migrate"},"next":{"title":"Addon Parameters","permalink":"/GAdminV2/docs/AddonParameters"}}');var d=r(4848),i=r(8453);const o={sidebar_position:4},t="Addons",a={},l=[{value:"Universal addon structure",id:"universal-addon-structure",level:2},{value:"Configuration",id:"configuration",level:2},{value:"Config Parameters",id:"config-parameters",level:2},{value:"Main module",id:"main-module",level:2},{value:"Server Access:",id:"server-access",level:3},{value:"Client Access:",id:"client-access",level:3}];function c(e){const n={a:"a",admonition:"admonition",code:"code",h1:"h1",h2:"h2",h3:"h3",header:"header",img:"img",li:"li",p:"p",pre:"pre",ul:"ul",...(0,i.R)(),...e.components};return(0,d.jsxs)(d.Fragment,{children:[(0,d.jsx)(n.header,{children:(0,d.jsx)(n.h1,{id:"addons",children:"Addons"})}),"\n",(0,d.jsx)(n.p,{children:"Want to create your own addon for GAdmin? Here are some requirements you must follow:"}),"\n",(0,d.jsx)(n.h2,{id:"universal-addon-structure",children:"Universal addon structure"}),"\n",(0,d.jsx)(n.p,{children:"Every well-structured addon should follow this format:"}),"\n",(0,d.jsxs)(n.p,{children:[(0,d.jsx)(n.img,{alt:"alt text",src:r(5296).A+"",width:"283",height:"81"})," ",(0,d.jsx)("br",{})]}),"\n",(0,d.jsxs)(n.p,{children:["Where: ",(0,d.jsx)("br",{})]}),"\n",(0,d.jsxs)(n.ul,{children:["\n",(0,d.jsxs)(n.li,{children:["The main addon folder name must follow this format: ",(0,d.jsx)(n.code,{children:"Addon Name"}),"@",(0,d.jsx)(n.code,{children:"Addon Author"}),"."]}),"\n",(0,d.jsxs)(n.li,{children:["Must have a ",(0,d.jsx)(n.code,{children:"Config"})," with ",(0,d.jsx)(n.code,{children:"Main"})," modules."]}),"\n",(0,d.jsxs)(n.li,{children:["Optional ",(0,d.jsx)(n.code,{children:"Assets"})," folder for models and modules that your addon may require."]}),"\n"]}),"\n",(0,d.jsx)(n.admonition,{type:"info",children:(0,d.jsxs)(n.p,{children:["The main addon folder must include the tag ",(0,d.jsx)(n.code,{children:"GAdmin Addon"})," for your add-on to load properly."]})}),"\n",(0,d.jsx)(n.h2,{id:"configuration",children:"Configuration"}),"\n",(0,d.jsx)(n.p,{children:"The configuration module must follow this format for the addon to work properly:"}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:'return {\r\n    Enabled = true, -- Is addon enabled?\r\n    Author = "@gdr1461account2", -- Addon author\r\n    Version = "v1.0.0", -- Addon version\r\n\r\n    Name = "Test Addon", -- Name of the addon.\r\n    Description = "GAdmin addon.", -- Description of the addon.\r\n    Tag = "EXAMPLE",\r\n\r\n    Parameters = { -- Addon parameters\r\n    \tCommands = "@this.Assets.Commands",\r\n    \tRanks = "@this.Assets.Ranks",\r\n    \tUI = "@this.Assets.UI",\r\n\t    ISettings = "@this.Assets.ISettings",\r\n\t    --Settings = "@this.Assets.Settings",\r\n    }\r\n}\n'})}),"\n",(0,d.jsxs)(n.p,{children:["Where: ",(0,d.jsx)("br",{})]}),"\n",(0,d.jsxs)(n.ul,{children:["\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Tag"})," is an optional key that gets added as the prefix to author field."]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Parameters"})," is table of GAdmin parameters that your addon uses."]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Description"})," is detailed explanation of what your addon does."]}),"\n"]}),"\n",(0,d.jsx)(n.h2,{id:"config-parameters",children:"Config Parameters"}),"\n",(0,d.jsx)(n.p,{children:"There are many parameters you can use to enhance your addon\u2019s functionality with the API."}),"\n",(0,d.jsx)(n.p,{children:"Here\u2019s how it works:"}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:"Parameters = {\r\n    KEY = PATH\r\n}\n"})}),"\n",(0,d.jsxs)(n.p,{children:["Where: ",(0,d.jsx)("br",{})]}),"\n",(0,d.jsxs)(n.ul,{children:["\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"KEY"})," is parameter name that you want to use."]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"PATH"})," is the path to the object that the specified parameter will use. You can use any of the ",(0,d.jsx)(n.code,{children:"Roblox services"})," or ",(0,d.jsx)(n.code,{children:"@this"})," to reference the main addon folder as the starting point in the path."]}),"\n"]}),"\n",(0,d.jsxs)(n.p,{children:["Find more details about addon parameters ",(0,d.jsx)(n.a,{href:"/docs/AddonParameters",children:"here"}),"."]}),"\n",(0,d.jsx)(n.h2,{id:"main-module",children:"Main module"}),"\n",(0,d.jsxs)(n.p,{children:["The main module lets you run code whenever the GAdmin ",(0,d.jsx)(n.code,{children:"server"})," or ",(0,d.jsx)(n.code,{children:"client"})," boots up."]}),"\n",(0,d.jsx)(n.pre,{children:(0,d.jsx)(n.code,{className:"language-lua",children:'local Main = {}\r\nMain.Server = {}\r\nMain.Client = {}\r\n\r\nfunction Main.Server:Start()\r\n    print("Server booted up!")\r\n    print(self.Assets)\r\n    print(self.Shared)\r\n    print(self.Server)\r\nend\r\n\r\nfunction Main.Client:Start()\r\n\tprint("Client booted up!")\r\n    print(self.Assets)\r\n    print(self.Shared)\r\n    print(self.Client)\r\nend\r\n\r\nreturn Main\n'})}),"\n",(0,d.jsx)(n.h3,{id:"server-access",children:"Server Access:"}),"\n",(0,d.jsxs)(n.ul,{children:["\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Assets"})," folder of your addon."]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Shared"})," folder of GAdmin (GAdminV2.MainModule.Shared)"]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Server"})," folder of GAdmin (GAdminV2.MainModule.Server)"]}),"\n"]}),"\n",(0,d.jsx)(n.h3,{id:"client-access",children:"Client Access:"}),"\n",(0,d.jsxs)(n.ul,{children:["\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Assets"})," folder of your addon."]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Shared"})," folder of GAdmin (GAdminV2.MainModule.Shared)"]}),"\n",(0,d.jsxs)(n.li,{children:[(0,d.jsx)(n.code,{children:"Client"})," folder of GAdmin (GAdminV2.MainModule.Client)"]}),"\n"]})]})}function h(e={}){const{wrapper:n}={...(0,i.R)(),...e.components};return n?(0,d.jsx)(n,{...e,children:(0,d.jsx)(c,{...e})}):c(e)}},5296:(e,n,r)=>{r.d(n,{A:()=>s});const s="data:image/png;base64,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"},8453:(e,n,r)=>{r.d(n,{R:()=>o,x:()=>t});var s=r(6540);const d={},i=s.createContext(d);function o(e){const n=s.useContext(i);return s.useMemo((function(){return"function"==typeof e?e(n):{...n,...e}}),[n,e])}function t(e){let n;return n=e.disableParentContext?"function"==typeof e.components?e.components(d):e.components||d:o(e.components),s.createElement(i.Provider,{value:n},e.children)}}}]);