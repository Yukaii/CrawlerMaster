# 歡迎

歡迎來到 CrawlerMaster 的維基。

在 Colorgy 的服務裡，課程資料、課程爬蟲算非常大的一個大項目，需要非常多的力量時間來完整、除錯。
本專案便是為了讓此過程更簡易及方便而開發。主要有以下幾個功能：

## 排程執行爬蟲

管理爬蟲上最麻煩的就是資料更新的問題。只有十間倒還好，手動跑一下就結束了；二十間也還可以接受，花的時間長了點而已。隨著支援學校的增多，浪費在管理的時間上會越來越多。CrawlerMaster 可以簡單地設定爬蟲排程的時間，實際上是使用了 `rufus-scheduler` 來達成。

## 課程資料驗證

用 ActiveRecord 的 Validation 還有資料庫本身的驗證。

## Todos

* 排程驗證，目前輸入錯的字串會直接噴掉，誰來 handle 一下
* 驗證資料完整性

## 貢獻此專案

* [如何增加支援的學校](新增課程爬蟲說明.md)

## Contributors

* [Yukai](https://github.com/Yukaii)
* [Neson](https://github.com/Neson)
* [Hong Ru](https://github.com/LinTim)
* [Boyu Lin](https://github.com/BoyuLin0906)
* [log3log4771](https://github.com/log3log4771)
* [幽默的調調](https://github.com/dengshun83)
