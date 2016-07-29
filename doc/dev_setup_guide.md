# Development Environment Setup Guide

## Ubuntu

### 安裝必要系統套件

```bash
sudo apt-get update

sudo apt-get install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev
```

### 安裝 Ruby

使用 [rbenv](https://github.com/rbenv/rbenv)

依照安裝指示：

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
```

修改 `~/.bashrc`

```bash
# ~/.bashrc
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
```

裝 [ruby-build](https://github.com/rbenv/ruby-build#readme) plugin

```bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
```

重整 shell（開新的 Terminal 視窗），然後檢查 rbenv 指令：

```bash
type rbenv
#=> "rbenv is a function"
```

開始安裝 ruby：

```bash
rbenv install 2.3.1
rbenv global 2.3.1 # set as global
```

設置 gem 安裝設定

```bash
echo 'gem: --no-ri --no-rdoc' >> ~/.gemrc
gem install bundler
```

### 安裝 nodejs 環境

參照：[https://nodejs.org/en/download/package-manager/](https://nodejs.org/en/download/package-manager/)

```bash
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### 安裝 CrawlerMaster 相依系統套件

```bash
sudo apt-get install libpq-dev imagemagick libmagickwand-dev libqt4-dev libqtwebkit-dev
```

### 安裝 Redis

```bash
sudo apt-get install redis-server
sudo services redis-server status # 看一下有沒有跑起來

sudo services redis-server start # optional，redis 沒有跑起來的話
```

### 設置專案

```bash
git clone https://github.com/colorgy/CrawlerMaster
cd CrawlerMaster

echo '
REDIS_URL=redis://localhost:6379/
REDIS_NAMESPACE=crawler_master
' >> .env

bundle install

rake db:setup && rake db:migrate && rake db:seed
```

#### 跑起開發環境

```bash
gem install foreman

foreman start -f Procfile.dev
```

就可以登入 [http://localhost:3000/](http://localhost:3000/) 了，預設的登入帳密是 admin/password，由 `db/seeds.rb` 建立。

## 雜項

### Rubocop

是 Ruby 的靜態語法檢查工具，有 Vim 平臺的 [syntastic](https://github.com/scrooloose/syntastic)([neomake](https://github.com/neomake/neomake/) 比較順)、Atom 的 [linter-rubocop](https://atom.io/packages/linter-rubocop) 可以設置。

![VSCode](http://i.imgur.com/K2Q9Vkm.png)

![Atom](http://i.imgur.com/juMUR4N.png)

![NeoVim](http://i.imgur.com/A98vyxs.png)


## 參考資料

1. https://www.digitalocean.com/community/tutorials/how-to-install-ruby-on-rails-with-rbenv-on-ubuntu-14-04
