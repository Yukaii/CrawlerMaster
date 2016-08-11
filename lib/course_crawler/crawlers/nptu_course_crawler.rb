# 國立屏東大學
# 課程查詢網址：http://webap.nptu.edu.tw/web/Secure/default.aspx

module CourseCrawler::Crawlers
class NptuCourseCrawler < CourseCrawler::Base

  DAYS = {
    "一" => 1,
    "二" => 2,
    "三" => 3,
    "四" => 4,
    "五" => 5,
    "六" => 6,
    "日" => 7
    }

  PERIODS = {
    "M" => 1,
    "1" => 2,
    "2" => 3,
    "3" => 4,
    "4" => 5,
    "N" => 6,
    "5" => 7,
    "6" => 8,
    "7" => 9,
    "8" => 10,
    "9" => 11,
    "A" => 12,
    "B" => 13,
    "C" => 14,
    "D" => 15
    }

  def initialize year: nil, term: nil, update_progress: nil, after_each: nil

    @year = year
    @term = term
    @update_progress_proc = update_progress
    @after_each_proc = after_each

    @query_url = 'http://webap.nptu.edu.tw/web/'
  end

  def courses
    @courses = []

    r = RestClient.get(@query_url+"Secure/default.aspx")
    hidden = Hash[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    cookie = RestClient.post(@query_url+"Secure/default.aspx", hidden.merge({
      "__SCROLLPOSITIONX" => "0",
      "__SCROLLPOSITIONY" => "0",
      "__EVENTTARGET" => "",
      "__EVENTARGUMENT" => "",
      "__VIEWSTATEENCRYPTED" => "",
      "LoginDefault:ibtLoginGuest.x" => "71",
      "LoginDefault:ibtLoginGuest.y" => "23",
      "LoginDefault:txtScreenWidth" => "1366",
      "LoginDefault:txtScreenHeight" => "768",
      }), {"Cookie" => r.cookies}).cookies


    r = %x(curl -s 'http://webap.nptu.edu.tw/web/A04/A0428S3Page.aspx' -H 'Cookie: ASP.NET_SessionId=#{cookie["ASP.NET_SessionId"]}; .PaAuth=#{cookie[".PaAuth"]}' --compressed)
    doc = Nokogiri::HTML(r)

    # hidden = 2BkG47lPUaxfH1AR4ZNGhv2ne8SZh[Nokogiri::HTML(r).css('input[type="hidden"]').map{|hidden| [hidden[:name], hidden[:value]]}]

    doc.css('select[name="A0425Q3:ddlDEPT_ID"] option:nth-child(n+2)').map{|opt| [opt[:value],opt.text]}.each do |dept_v, dept_n|
      # 先用已知的hidden
      r = %x(curl -s 'http://webap.nptu.edu.tw/web/A04/A0428S3Page.aspx' -H 'Cookie: ASP.NET_SessionId=#{cookie["ASP.NET_SessionId"]}; .PaAuth=#{cookie[".PaAuth"]}' --data '__EVENTTARGET=&__EVENTARGUMENT=&__LASTFOCUS=&__VIEWSTATE=HpB3eB0aKWBjQckDV85sLX1Kmet4uoBfXubmm5FeEL6BTAez0uj2fVDkDcbEhppLYgT7q%2BNvQZ%2Fa5BhawWb8g4zpvTSVRFU3Dprfy66jh4JyxvVeCuAZ%2BJ1Tx2k2Bzi1Qqe5GIjrpmn8wmWL9nqLNXQXtOmJ2uzd4qMBKua2So6UbfpmupyXKPU3Nb81Xn6R0glxrOd63qVU0hBbDmRTV3hGsn%2BS%2BFJBNkR%2Bnb%2F9KxquROTVK%2FnXqN6cvQRIrQq1plbSW7ocV1REiSteV4uzQfKRmBTHu36q4MjX9%2BpUz825V46wQ7lQyo9xa6lcPd6DxBZy1XGfi6kHv7LBiDY3Ej0AYNucMHYcKG5MEFlMgRC3upkSYwoqFvUfcDpHt0wLnKeIUZWOx5IxKtlKz%2F8P6xpXAkTeZElJuszs1eYqm7GsjyU8hPeQT3hD2qptvZBCMm8VMfGpV24GPfgQUKk8R%2FBIeDZLH0VMLsSjhFHyRrAkz9X5bYtbKmr14s7rqPaoYlUEZf37aoc%2BPSlc1Aqrk489RRCdRaCXmmLnUK7Bn%2Fb3On0rY8mQP98fgO%2B1CVQOvVMeGWwXyp1LnWwPsHdCDWnklFyAv8FA6XsFJh3y9ZfSuCDv5QBJLqt84OvTBRx6O0SRTZ%2B1lZ6Xq1FzfavQDQr%2FKGGCJ3KFHrWx9iZot3wIaLd636lCiYqMl02BArDauDluZkWn6NvDkjHGa2%2FmZn4tKNZ0ZkCI3tX1yaCeK5dGYev3n661LHF0zFJqm5cznWVkNGN35xu9rNbQATMdSAGTDfmfqGYxON5h8if1JAKG7KZR61X5tQlVMDWenWr7eS5qopEN6BE913YqW4HItbeoCIdedeXsg29%2BS70egqqqlQz5LZcJJjQNdJ23g9MZiepKrktJ0iVcoCvIds5zKFA%2FzoiTeFE42UbGiSo4GzfbF6dFiTavYuu9W6wkZv6MaR%2FnuSvsk%2F4XInf5neTq8UsJmz5Aq6sww6ISbrFYHeze2ggTI2U6YdK4lco8zFxJKoAU9qh7S%2Bhr962m2pNzHFgCAYjF%2BxR93Hc8mynpGpwkN6XJjkwmnEAdzvjPSmCqGmh0TAvWQ2pVvVBD%2BFlC24N9ehh3pvwcc3GFa6PErO6RuEvK042mJJ5lcYnURpTLluk5BPGcMAL%2FFeOy0bBCtQYbIF3zKplPeJQycwlbZd5PXEVpC1JbfUfGHACy7zu6WifXgiap1aWZDf5rnv7ip%2FMY5g7fXBFU%2FU%2FRB9qlEuPYqIypHqFSQ8AfWi10XcwZ7FDSg5N0fuTJA41mPfwvXYYMcvq7xCNLsF03%2FjtKeCYjLhNWSwUycZrigktmrXVkMU38Q6M0zXxwLxrQP8rJTIOz%2Bpx%2FbX8Mb%2BGz4zieWKwBJY7cFUEMxTbrx3dFlnsCZvAE5kWwW2VC9YtzyFvUDofF%2FE7OS6i%2B3pmW1RojucFK%2FI7SB0cIkd91CARKqBCAJnUYEzJ3sXveL0%2FfydtofN%2F8SOJz9MovSPkNZTpnBqDJNt2Hzsy605puvRK%2FjzOCAn%2BGHUAtMjsupTPxYwkbyMqyMNEv1uxF6N1WwfYlSw9gQoY47PGCvjzThUBQpNLdULh3JCQsP5t48A4Kn7UAJFqeU4aD13akeUByI2CA1DJb%2FPp9%2BTg1mi6XMubmTGsKs93fsk%2F7%2Fpswt8o%2Bi%2Fs7pZaj6d0dw3g%2BLMKc5SUgY1RhZT9JuDQmLaxUQalGsSPZXZSp8iX96aGV495KJQ8lQQeqkJrW19j2Ffaueu7Oxnamm0mwrP7%2Bm7CmIOzUK4KaHjdn%2BUjtTguFuRiMpIM8YDgKiLiwkC8Dbgc38kOlAkRsAtjwtDg788j4p7FAVrFKlKVPwesHXIw%2BXssU9VGogbKR3hKF3V1IUVFjNZWMe4YOfJ1Ibeq7Yg%2FI8D8g2TqXRNmM%2BFLBVjBLqBlzvxomJnNr0U76l%2BkdaHueS%2FACwiAiOmsKRTazAogMphwxLGhplyUQYQtNPsMYMtECtRhZCL9Al3thWS59BWR0n5uYEZQHNjJBVhu525Ld80zen9gc5bgUGRQQJGpbxqhIVeFXoWeorYP4l4pOTu6wkrJ8tUOG75uUQb9S62OMY521UqWBfq%2By2rDF%2F%2Bbj8PbbFqXH3h9al3qpROPxilQjdCGD8T8RaMFaQ%2FMdAipemE0tIGO5II05B9I8xIPPc1qkeDui2KvMHHQ10LZJQQiVgm%2FwxlowJFFWeGOX1IuvEssPubuqjBSNMKr717UDW3O6lyEPrjOqqgSvUVIp7AFFabH%2Bjk40nRi4mpOuZDKEMS8aJcCpX7mU5w%2FO7ZRY3ZyAnoaCZZ398cICtITCnrp0RABWqR1%2B3ZNFxLeD%2FxWn4%2B64Bxp6x%2FfqJ9a62WjEvsrWkI9nqKuVkJbB9NfQyo0NF9pPSXWmthNxp2nyyZOkz5oxlyTm8gVK6swITeVs%2FIEGxCt4mLdaP8GeXg91lxYFrJn9mPa9VtmT7FTK2f3948yVjAkP7nLzDVD3tJ4W7jkgqzjIz9T3uN3X3hPHdxigN7d1fUq5u%2BAuYEX1nUOIkbP7S2Ln4P1BLhTigAX0Q2qP9SVa%2FxyEftX%2F0a6zCX%2B4GiTZaq37DN3nxNx4nU2mtm3kejiLmazhVCDC%2F3pWs4582TjCobi%2BISvaW5LYC3WaA1A0YCTCH018y4d7djiXlBVbJVzKUcxt%2FIH5ncYdS%2BAIcsHdx0hgRjHfvzAjL8HAonVdNuHInfWRGOLQwrxC9Iv9lWeaTRzm4XeFvbpwI%2BlbYwt7n%2BNXZzjuXbu%2BMEuUyanKGJXz%2FVsv2W2%2Fl4plVmMaEB3xa4f2Ux8%2BcuFsgtVCTUdVmtJpgXFDV44AgDEV3BAmljs%2B%2BHP%2FSjzwcA8keWUtCAl0v42TZs%2F7hneRP1peCVGP1pDsBlhLVN84wBIzjHwEXnened0bBYz%2FOwez6F0oMuaI8CEsXXzZlMyvEvXHA6RLAyund0l1EQv6E2nuU%2FIp%2BpEY%2FgqGm0sp%2BSxNTX7IJquwBPWftwHDAUt558dr62Qp8iT9gU6FB9BqA7paDIKT6vsoZQcpQizR%2B0YYPJz2Z1THgSebXtF7pbsxJjxnrAIvm1ugjn9tOE%2B5Ee9bTWV%2BF3ppj1tlYRLVnf0leq1ZZNU3L%2FywAma%2BFS3buZWyk9f2O%2Bwc6IDDncAHZYdXu6Riyg1R9Dtxb2R%2B9MLNnawV%2FxYSrH225aeRmpSi%2BBvIsx2N3DkIe6Bh3Z0FeRop3fC5ndTG9%2Fu3Ld8Ol%2FVStMMwgrtdr4tC6k15j8oEtyBUAtfx5lhD7GMWDc%2B2OIwR8KMwF2mYgHgaCLsnI9jE6yZWbIR8PLsnQOdUh1J41CqP5Pmkqy33C6XgYRhIdcaRmX00CxQCPr7QvSmDZEfW5nF2eycW2xi7CQpedv%2BuT8HID%2BmIvwi669NXG6CRg0rW3l7fs4GbzQCGBRS%2F4lt8Zy5P9Puv1w%2F8x1APy05cRO80WMUwLKyFYV7TQeqZzzraSkGGfBgkFxwIXeku%2B40utyRRP8PfsgXZQEmkWSHbStrW9CyK7bVHilXJxMXrxRtf7weUqZNOBQKNk9T%2FtX7Jjc3gkRh613vinoTkPlJhb3D2g5Uzj3K4p8CGJnDYwHsrOMRnX9YR4BBEHqywGsNKEUnmBmoBEwpDadK2VGy57mWV%2FQVReDh5nyPNhb4g3kd1dsfg4CS6DNgjtLph9KnL9spFB5mJaE%2FBF2XcZZShq0uzx2RHfmVf56Xo7CL%2FUIuMApKku%2FX1K8A%2BayCcfATu81UjvQhX2eZru5rJ3yYPB%2BbRhA5SWl5dXrA7SndyUPj1NE%2FcAqkKb0zHCTfRoA%2F9Q4uyY03812tWqMgKeXKlHEaBn8RBDjqWjJHZkCyDI27au97oOlaki6cGlRCZ7mBB8TQ9CHVLcFAbsjnEk%2FcbzBOVKcABuOh3TNH0Dm0qH54T78LU6rEq8h0ooedoyeWkScdn2NBX%2B24jmST5tohlMR6iU0pICfLiY7PHO4FXx6YlCDKocKDDlv7SdMMCtdSiJvXOH2VgoLdmN2vW7jEGPLZ8O2F0XNh9xW5GQV1BKT4PGEnuUiQzxcVjsUxJHZKEYk7hBQTRqxmrglKHcBnhEiQa6baMsOSKp%2FVWiw6t1zzhBTnuRi36onAUkqomS1BsXamOl8l3kQeu6JmXb05cy%2BbVDhWFq10kbT4y8UrJFwa6fvoL98m%2BAMzzjR5tt9EeCHE5Lz3t0%2BDG7unSxqVpw8Gpi3jzyGX8eM9K7%2FDDZe2AjS95QJpJRToZO8D7J4t8U0CGnjUbzznZcOwLc1Ej97f6sxoQoQe8fr93dR18%2BuagrDzySZh7NdKFTl1AVV8mbieMYPKO%2FvuT5TWp190usvYLs%2BUIeM0PvkmCWpaTO1V5Q5ic5wYYldrYdazpqxtEcZryAibvpT3AfkYIFVYxVH8YpdvSJke45DY0wWSjH4nQfi%2B1lyUAz%2FihNFin3cBIDA2sTJX5z%2F252J9%2Fdj0UVCtUIFcSXZ0BfDThCzb48805IqGEYafGN4OrLapsL34hyKMi%2FgTiHOBG0YiYbexLt7RPhXEG8Jv68oiBpZ228iINAK0iwsUwTZTyJ1E1xYLq%2F51GNmzpL%2BUTmjEJVJcM5dRpu4cx5ET8Bs0CVE3A9T%2BUhlyewJPxiWCHZxNQjJ1mfQO9gVO905ZcTbqgW7z8aqL1TrK5%2FAg3M4D23Rc5Q5RZAcjudVqSZejsR1wXTgj7%2BClq46N6Df116IE2I%2BVFtZpTp5vasy%2BuoFVcUDApVpFGOi8mahQN7K80nmzOmj8LikXurwpMpIXqB6Bm%2Bj8xw4gMAzJ0%2FQflMOWOfwH7xkr%2BTOKDX88uyD84WpV2Heb5pZGT9noA7YWJdD9G%2BHu4En15hpxvY0ctjUuErVT2cC8TI922JqX8gQWWXP0%2Bi9Xm4%2F4RkH%2BrkwvBCe%2BDfTg84%2FA9fEOuAaa3MrvajZY3dcUpDRJEGutOp97gt73e31BWQHFR7zPlQ5rPzqy%2BROpypn7w34VFEDxrs6d%2FxqJexrh80R8JhUJg77yzb8OvIZS5mojWsUxHdgyh4I%2BitY7SAeodqmmqpe897AiUGdn5YRsqjDCUJ5MbCgQNuTacBGyV5eTrIpfRzm6xD498jW%2FsAs89PtrUBvu9PY2mKtkkfBm%2Fv4rdTXTLQ5y4w6%2BbbDLyLK5aMQlPWWjyJ4TSTgXmmMVuW%2Byokl%2FJiK%2FK432n2tciKqoAe7IBHAr51WyHB3mXPzwOQfVUrDYdhbNjcEKZJNoOLdDSzRPB1P4v%2BF3vKZi9vyzupMXF3UsqxvlGkKi%2B5gjQ2ObAzXV7YP3szDIdQVLCjV2uy7QqV2oFSytwjlDwdX%2BcaWPvbVAbl5WV3OeIuz2dMzjOGkE8yOL1W%2BfAPrndq54EW8nnTfeo5vrQDK0YUA5OtSgiKuMpnOImsokbfPOOEfhaD8AFYaPHzc0JlfAcysVcGY5HJMrTswng17wjTTtQDdUYA7sLZAqAxyM%2BqUJmjXC39i%2B1pQoea2xmhdMk0Qtb6J2FPhiFIuYBmXNCN6vrmHMCDAK%2FKBapIjnHU6LCLVN6U8SwTJ2ePKvscMH8jsReDP5jMD1lhcxqiqCXcXluTjBSbl9rWsxmQguMl8wkAYmvrl8PI5i8JYaPp4NaXxV9Jjzbgr%2FRFZQxwReVa8yQkvaCvBB0ipJBgVh%2FA3u%2Fst%2Ff8FaHI3zUvL3UiDUqtqdOp1Td6DysLg6c3GOh9i33ZNa7%2BYzhhJeGi8kor02WJY5mSSBJYPRMPQx9G3xi4JSs0pgjRCPi72ZazOkjz9kY2092ZCrSzmVlLu8BxmqHEu7KE8GFsWRAkw0cez21WeYyHtOkVyUgrT3jGw9Os9cvYzRuh5QwplWt55I2%2FXP5Y2OXj8zo8DAOBTRO0jKS8CnczCC%2BZMIyfQT2tcdIG9gGwLNAFESchrTNQ9Qv9LTWt4nFR7qm5OdUgDCRyDaK4YEA6whiPHda88icWhtLqSCqZz3lJZXvzhve%2FlZxqrXlOhdrt17qpv7kTu2Jh%2B7RywzxojlaYf3zl2ZnxT8kYzNSxBpkUj3qmKBqdBtEXcZiYY%2FSuLi%2BB2IR3jc7uFV6sxsIP3llWsWAZ0FoitRTU6G5fSrpD6AkJXPfmXYsjnOAcu7uSoq1miY25x3elA6ZBKFjpV0B068qo5OrXX9RAoQ%2B%2B9%2Bwjl4pzXXmNpclxHl6mR0BE%2FPOX3fJQZp2zR80i7rX55WzfKZo8YoMRCXR7hYfpRhnSmp4l%2F2YyRuDJbEMPNt9x63jtDFDO9gMJaAAT0jXVFUXoEb4wqk98uXqtlZnvh7g7DB7UtXhvcJTu47%2BFSPOltokHUFY3v%2FyGUo8Mn21CUk9VUatDi2gr2RXWzR4vXiN3rCThXOvH5bKfPChc6R8CZu9a3plOW0bs00UDWhWowpKK9BCrdgSf%2FZNcs4y2QjV3Wnh94JpV4KaWhrpHQY4oXcfoKLnvmgBmHHQsdofwVY%2F6VxvyVonioLW2zQe3aPyHQK1FCuGVr1U9rBzeSJJxNgxbFGZ6CSFbQ1X8aQTYSwllEBncuzCGpXPfacTqYclTLQ%2F5WEAWpId6oCzbj5wDToKHi81hlNzhsF4frBflEmopa1NX20iJgbCrZIOd0gIMlRGjLMX%2FhTay3NKNs%2BwCGXAIimLPP%2FnMErT1MPCqDYqSpl0qnVfqAE5Ndp68QuofR28gyYHcJGrKWiTa9CJtGS5r258FBy5GOJzHvuC6QS9qNvpDzkUwgs%2Flh%2BWO7WnPMINs%2FzgyBNzaOj9JCdrv%2BbzdcuGtJrslnszhmgsC6b11BAsPRu1TAgSycJHoeNNJZbgd3WmPRpp4po8TiRIpFJq6Buod28YNPGE5DqZ49Orcosu8HSmB16t%2BK29csYDBym6IOgDn6q8osoGRJfJYIAFR06kHHLxhyb%2FP4ix5wOYM8FeSwSyDqOKyZtpwquEG2QKXhqW1E0fsW75M4excJlXyqx73YttHzcafqAoBKJUo8sHvcJqAOBEI3qvWT6IKETq%2FK0k%2F3gLjDQ2LOB9TsQQwO%2F2ufh3QVigKMGNVDAsjjmhDGJkJjw7X4hZQ5oaE6DbQq4NbDuN6W1MmpgawCYSh56kKcSZ2heAzIANAB%2FLBqfSNdAfmda5Ft2c1VlmycCt3uRAku46yfhLgBh7dwmCA32Ule7omH495zDV7vq4gPMX2U1cZfSxzrUHmsfo40xh6H8wHd3kWeu5BZNFqsMXXtsBmKuKHvTSkqpay0M%2Bpx938EouXwcH2%2F%2FpzhnseXmGDu9B%2FFRiFztRj2XL9M1s5qHwccQiBQPom1N%2FsM2hCccgV50NlwaHujxcVvYX9G2NnoHzlsqOJXCkkVxYwWaCIKELYW4I1W%2FD9iJc58VNLoAfL%2Bl6J477XGsnbliQwfwNvQguVq%2BQNV2ziDNdTNcb0LdxiGeCr8N7%2BqkKAJ5Qpdbv3goSb2meXu7kO3bHv7faAMVEpX6caWZPK%2Bn1tDNOrT1p4kAPDVN1qyZE0GGZvoGNXjerkASIo8CohpzlQJBav2BmrMfcVqmq67OuMlrKIu2w717xcNVo%2B%2FdMXUEtKYxBQuUvgpApGwUeXyADQqmn6YvTG66gpXbFOKyoRoQFu3%2BSiMji4BCq02EHYyYURJHBA1tmbb0JshIDyM8%2FgG%2Fh0%2BVFDTS7y%2FUpMBdsbS2ZI3GXH1mxF7ZUcfdYI8kbr7YpH8orG%2FM1pQUfyTNpRodQ5lJ%2BueqK9WYr1Uf4Q42fjJRGKHP4KRe0wZfKk%2BEQIbu7LOoYiAX4re7SaQD%2B4GwPNsJYTN9GmCGDJ0iP1iq4gZm85%2Fm2BdzMZ8hLvzq3JazyYG7Z248y8mfj95AVp%2BGthPBiJn05dDRZ2628aCmFLxwsvKtNXA%2FP0v0pKO07XCKIxhdDvXUSn1IhHHURIidA6%2FVfJqU%2Bvkx2a2mcCl0LD%2Be%2F2FHc7bZ4aeDdbvjW9JnzdGsvxipdbsHvSon8s4mn2YN3H9R7sXrBnvRVx3K7zMKGKlBroXCq8Usvi9lqfzhcHGLhleIBaPiA2UGkkJtQb0fUfug5W12IKUkaXDBognAwqQ7MstbC3W3LhyMhBbIa2608ybhdCW646eI%2Btz6G1yIcVyqlucZ2JIi3fxeX5GzMkSctyFZpw4XT8heZaDr%2FEf3iSZSKMqgmbodVOpAqxVORPjKZd0PwPReGpmHmK2YyhQXW%2FYATqZCWial6isR1yKBzl00QUa2hDP5ERZf7gXrHq08lWMYTSnM3rlfyIeHoB0hgHoK92JlQCtXX6KYkPPRI3wSPW4TX8YcupCIX5vI%2Bn9%2Fp13Q7r0L3VV5SOKlabVvshtschEWpN3jJmTOWFqGwrRCAVcRPxP2ABUWM20c6vXzq8nhav9XM%2FDMP6yPjEwkee7%2FdXmtRbYe1cQHYU9ranM2rEKaoLJ2DACsk%2BCfY8VCgOHnlci2ZPvfMsyn5UHxpL3JuMU1HV%2FmIx%2BoJp3EsoRgqbB7CVsGTyDIX5yn2u6v8j1lYhDhoqnzsLJeCIb9hW65oYaj7lFVVpEyN0RjyWl%2BqZLG0TyFWrKgurlbsgzah6wGUhj0M94HQsWZvW8OdCSLLWHRQpdB0vMPm1OuWD4cQRCeTL2ZlPhI3na7ZDZbqTy%2BeO%2Fo4Q0ADv8Iiw4ERxVaVVhD7sBGDo49XR7bqMz1AdFLDEBQEOJddgqCW6szrcx4xpp%2Fq3duyF2AST6VTS4889EGOzSUZkpNPlybbcjwQ4XUK%2FRcm%2BtXcy9diBbk%2FSsC8mo%2BRJojjwbZ8dEqvl0ImMVkKMw6kMczXrMi3YHKhO39TjkmmmSssaJcX6UtdE46PFlekb0VagvxIwhetych9Fa%2FxOt5Di1GdwCFFT%2FbicEOwsvoPPuWbOEJ5%2FqSwn4RhpoRkAAp6Wb%2BxenLvux62qJmOq9QD%2BjjzSsRiFjuYoNXidutiGIogLlIcR3EwQyNu3DusEPcd0wYiBd5SBUHmoSbQADa4%2Bhvxire5KOHdtPIfIgicKA9A65Ff%2FI0gPNjMVbto1OFg%2FwiVxUBI0tEsIUJnGQXX6I7usoT2EPYlJKH1VziHBfeedRXtDTekA4QX4uvbS2%2BEglhP7dEaLanL4PdoMgcO4QDcxm3ehP4%2Bda6Hvi1%2FZmtD62iYm%2BET0kVsiwtAXDpvWuFnQCtYDWfBXgCqEYX%2BZEjvZvu2qSlNs9kEArjiN28k2mbmEwAtXhPiL6hvm3zTIGyNPiC0%2FZfSU4gFGIue9bacC0ALGvl%2BcvIsqBemgrL9x3W9djuUFGX9zjFj1Oiw83duyd7S7EinZ%2BiS9FvmFW3I%2FWOXcg%2FVXfx0J2C1%2FzekM0fpaPlOQuO1N2CSeN3915Am8%2Bm7huayER%2BP53VMZo8EslxAH41B26MnfcvN5CkwPPC3bL1BJonZIVl9WycUWADs6oKElipfgLz3wAFowIyc2YAXoBafrXW9X84X8SMsmAIqkEEvt7D3XjODruk8DPvZMv%2BVuTvdKRdhazBBPRYsYgprw4nRvFq1Xhpz7xlWXjiZo6OkPBGZmUAIG2uxpCxCgOa%2Fngq20qTrwnBXJCBhJB734KZX6Negy2YpsLVTrnGSDa9IaJJ9X64l8yQFxR84jqSg9XnYIp%2FQH%2BiXQ0plBBP6ZLnTRkr7Jw3SeHnz%2FJbU7%2B%2FvznJkuZEcl8FulZi1laY9dfZfpilhiod%2FqrWKaGc9LMzcNdRnMmkBZCiCLBz6xHdemYqgK9X6G8J9Q1KYhMfVuqIORzgcJerTwwOEVCrxHJGyeyoXGVa8a%2FLjLobhFDxZIzyI8mXW%2BkG47lPUaxfH1AR4ZNGhv2ne8SZ%2Bza5k8RXg9NO6gYpVEx%2Bassgn8YLr7kUmM0KuX5Q3qrN3l%2FnQvOtsv%2F0payy%2BRJZV%2FJukz1CMizf0CNInx2dpgERo9IO4frPiSUzptsF2Z8fUmRixJNb43siCRyHP9N8LY0rqKH6XtgMPgPkG0hc3&__VIEWSTATEGENERATOR=991BC0AC&__SCROLLPOSITIONX=0&__SCROLLPOSITIONY=0&__VIEWSTATEENCRYPTED=&__EVENTVALIDATION=v9Q31e2v6wu7D6T6ZTNJ39qgG6O8nqLmKlOYyGhIf3w1ZL4JIZvLyhqK1iOtGhXvS4N68uwKfB0InrYa0IO1Z0TtCW1l4IuH1YHqhK5LGoGI4ikOJmsrmURkEMo%2BjvG0eFjnJ4q4AdR2yFLu5cM%2FfFd2djdTGuACfjl7AxSgMvPQcPQse2gLfR2RYKSif%2BLTUXgZ9uJPL6WDc1SGwPQ%2BYv9zU2OFioESt5Ytq0sEBjbzA8gnrmMgxIMLUq%2Bm%2Fsk6TDKTjvizSQhiFfZwwE7gsmRJszRB1TZR4zQPyp7B7VnQFUC3dDO3VjoD%2F8j3pPOObFbVil6%2BuiAQvKtLhK6FLXBqO1ve3o3cuofSF5UnWUmQMXYtNrixbUldePDfJcOfrw8iVdvxBJTv6hzZxG7MuB3r7u5cj%2BBMJwtCDKW1%2FePhBeFMTKkv4SkxJfqo2QxX11TdnjJnCSoneKv8EJ201WvJWbVAJurKFfX8H05joK6GS3p12AR1eYvnwav3uDfCDoJoKSVW1xa2EdbCFsWC9SPpqDqJ5yjRJjwHhywYNlJWWyb6ASmWNC8Z%2BwAMihBv1hIA%2FSAgSpbM%2BwVTVpcfBG%2BYm8URlzvSwnbdp7Ryli8pnhF28NHU3b43zlYPON8MhYEo4ZxgK%2BS6PL9ssAhJ%2F1JTu9Emh3r0DtbpjI9TQRD7f7UqDI31PJQ2AnrxEW9tY1MvqxHFIB0RbfEB6ydMDPmcrPyE%2B6QSlCqYBa0Ikg1xLiuzDviHra9cvWmUElgfVSuX3%2F0NlE1uAlfOGs%2F8oKbuwCuBDIXgreylPzpju3%2FPWFWqqnIQKWpZCJ3sVISVTfzSGdEOm%2FtSkc5qAaiSnXiBEHvKyj%2F%2Bz3SUeVnszdwj56jBMoceqliD89Tg4iHn66KnhHvm74kfcI0QbRGT%2FIlJ9ZYZLbW0Rian5TYb6kMcrhtqTdbjn70rbSns4YA7E43VEyrDEPPOoJQHDhIeDZ2sKQ3gJQXn6nYbXyodr7ySTKcDxVyKebZ%2BxUBM448CLW5j%2F0zmpjTK0aFGp2545NLVEl1A6I7VnZCg9Fo%2FK9bdibae80DXMkdlwcSwg18dx9KhvPn6VoOSZ5OoI9c6BbZNlF5sKYH0m43rpWbmQV809oGD8nNsd50Qteyp82OoJz1w0R8oMVGx%2Fb3O%2B08oecDCmNTeSIzGaah4PKqTHONYsxHRWlvUjK3OwB657LIzrWKq1zfmquKXNadvc1T4KcNDO2ZKJHEjcptjvW%2BxEHv6q0gir%2FTs5uEnR6CGPP8C%2B2gzIi32qNaxIvz5knSVX2B3oXP%2Fo%2BzY4P3BRQC3sSavvGaSq42tpFvcJzqB4CR%2FIYi2zD9kWhSAI7pC6avbNrN1whCPZA291zMLS%2FCmeUzX%2B0BPbSGzhk6Z%2BzoJhHW%2Fgbm9TMlAyYi8CLm2GUdiShr68Wp7f2a8cYkhX2Y1mG5lyIyJlop7GoTPbEgB4D3xyYHf%2F17qh2K%2FuedBBHbKcIjuSeXJ8Fc5qDOL6iM8X0cNBY%2BNEqSc%2FAp%2FnI7r9TVMWvomrw%3D%3D&CommonHeader%3AtxtMsg=&CommonHeader%3AtxtUsed=&A0425Q3%3AddlSYSE=#{@year-1911}#{@term}&A0425Q3%3AddlDEPT_ID=#{dept_v}&A0425Q3%3AddlCOMMON_ID=&A0425Q3%3AddlSCH_SYS_M=&A0425Q3%3AtxtSUBJ_CNAME=&A0425Q3%3AtxtEMP_CNAME=&A0425Q3%3AddlWEEK_ID=&A0425Q3%3AddlLESSON_ID=&A0425Q3%3AddlLESSON_ID2=&A0425Q3%3AibtQuery.x=25&A0425Q3%3AibtQuery.y=15' --compressed)
      doc = Nokogiri::HTML(r)

      doc.css('table[id="A0425S3_dgData"] tr:nth-child(n+2)').each do |tr|
        data = tr.css('td').map{|td| td.text.gsub(/[\r\n\s]/,'')}

        course_days, course_periods, course_locations = [], [], []
        (0..data[10].scan(/\d/).count-1).each do |i|
          period = data[11].scan(/\w+/)[i]
          period.scan(/\w/).each do |p|
            next if p == "0"
            course_days << data[10].scan(/\d/)[i].to_i
            course_periods << PERIODS[p]
            course_locations << data[12]
          end
        end

        course = {
          year: @year,    # 西元年
          term: @term,    # 學期 (第一學期=1，第二學期=2)
          name: data[5],    # 課程名稱
          lecturer: data[9],    # 授課教師
          credits: data[7].to_i,    # 學分數
          code: "#{@year}-#{@term}-#{data[4]}_#{data[3]}",
          general_code: data[3],    # 選課代碼
          url: nil,    # 課程大綱之類的連結
          required: data[6].include?('必'),    # 必修或選修
          department: data[2],    # 開課系所
          # department_code: nil,
          day_1: course_days[0],
          day_2: course_days[1],
          day_3: course_days[2],
          day_4: course_days[3],
          day_5: course_days[4],
          day_6: course_days[5],
          day_7: course_days[6],
          day_8: course_days[7],
          day_9: course_days[8],
          period_1: course_periods[0],
          period_2: course_periods[1],
          period_3: course_periods[2],
          period_4: course_periods[3],
          period_5: course_periods[4],
          period_6: course_periods[5],
          period_7: course_periods[6],
          period_8: course_periods[7],
          period_9: course_periods[8],
          location_1: course_locations[0],
          location_2: course_locations[1],
          location_3: course_locations[2],
          location_4: course_locations[3],
          location_5: course_locations[4],
          location_6: course_locations[5],
          location_7: course_locations[6],
          location_8: course_locations[7],
          location_9: course_locations[8],
          }

        @after_each_proc.call(course: course) if @after_each_proc

        @courses << course
      end
    end
    @courses
  end
end
end
