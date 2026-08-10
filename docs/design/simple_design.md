固定IPアドレス自動払い出しシステム 

簡易設計書 

V1.4 

2026-07-13 / Rev.1.4 

外部発注用 最終版 

 

 

改訂履歴 

版 

日付 

主な変更内容 

0.1 

2026-04-24 

初版（ドラフト） 

1.0 

2026-04-24 

MACバインド方式を廃止し手動IP設定方式へ変更。ARP自動検出・自動登録機能、段階的自動削除ポリシー、DNS自動登録、ARP収集のPython+SNMP+Meraki API化、Windows IPAMカスタムフィールド設計を追加。ホスト名任意化・DNS登録スキップ対応、UIカスケードを3段化、地域マスター粒度を都道府県/国に変更、Segmentsリストを一次情報源化、OfficeLocationMap/MissLog追加、ホスト名命名規則確定、承認フロー/削除機能/終了予定日を廃止、IPAM+WorkerをAzure VM上で同居する構成へ変更、バックアップ構成を追加、事前調査チェックリスト（付録C）を追加。レビューによる仕様変更。ARP収集頻度を1時間ごとに変更。セグメント同期Worker頻度を30分ごとに変更。一括払い出し機能を追加（最大20件、親子構造）。空きIP閾値アラート機能を追加（閾値20件、1日1回）。削除通知にManager追加・異常系のみIT部門通知。多言語切替をスコープ外（将来拡張）に追加。認証基盤の表記修正。ライセンス要件を補強。外部レビューによる仕様変更。一括払い出し対応（IPRequestItems分離・BatchSize追加）。セグメント同期Workerの申請タイトル・デバイス種別廃止。申請画面の注意事項エリア追加。ArpDeviceStatusリスト追加（SharePointリスト6本化）。IPRequests.RetryCount/NotificationStage/Archived追加。IPRequestItems.RetryCount追加。セグメント同期Worker頻度修正（日次→30分ごと）。自動削除フロー更新（ARP機器単位セーフティ・NotificationStage経由通知・Archived遷移・Cooldown実装）。ARP収集フロー更新（ArpDeviceStatus Upsert・72h連続失敗検知）。エラーハンドリング方針強化。18件の論点判断を全反映。工数35.5人日に更新。 

1.1 

2026-07-09 

外部発注前レビュー指摘26件および追加ヒアリング（H1〜H8）の結果を反映。【算出式是正】固定IP範囲＝セグメントCIDRのホスト範囲−動的プール（スコープ範囲−除外範囲）−予約IPに是正（7.2。従来式は動的プールそのものを指すため逆）。付録C.1の確認観点を動的プール内の固定設定機器有無に変更。【ARP範囲限定】ARP自動登録・LastSeenAt更新を固定IP範囲内に限定（2.1/3.1/7.3）、UsageCount集計を固定IP範囲内に統一（6.3/7.2）。【IPAMレンジ同期】セグメント同期WorkerにIPAMレンジ作成・同期を追加（7.2/8.3）、CSVツールをレンジ初期投入対応に拡張。【削除通知の明細化】NotificationStage/ArchivedをIPRequestItems単位へ移動、NotificationSentAt列新設、同一申請・同一段階の集約送信（並列度1）を規定（6.4/6.5/7.4）。親RetryCount廃止（明細へ一本化）。【払い出しフロー】LastSeenAtを払い出し時に初期化（6.8/7.1）、Processing滞留回収（30分）を追加（7.1/8.4）、RequestIdを決定的採番（REQ-yyyymmdd-親アイテムID）化・明細参照をParentItemIdへ変更（6.4/6.5/7.1）、Worker側ホスト名再検証を復活（7.1）。【競合検知】Requested IPの異MAC検出時の競合疑い通知を追加、「IP重複100%検知」の適用範囲を登録・払い出し時に明確化（7.3/8.4/付録B）。【Cooldown】全削除に30日Cooldown適用、期間中復帰はAutoDetected扱い（Requested由来は通知）と確定（7.4/付録A/B）。【通知経路】Worker発アラートは社内SMTPリレー経由、manager取得はPower Automate（Office 365 Usersコネクタ）責務と確定（7.4/8.3/8.4/8.5）。付録F「通知一覧」新設。【セキュリティ】付録E「実装規約」新設（gMSA第一候補・秘密情報保管・SNMPv3優先・例外処理規約・証明書期限管理）。DNS書込権限のセキュリティ部門承認済みを明記（9.1）、IPアドレス追跡（ログオンイベント突合）を削除（9.3）。【ARP収集】ArpDeviceStatusを機器マスターと位置付け（冗長ペアは代表1台のみ登録）・マスタメンテ対象化（6.9/10.6）、ARPカバレッジ突合チェック追加（3.1/7.2）、ipNetToMediaTableフォールバック・LastSeenAt書込24hスロットリング・IPAM反映のPowerShellスクリプト経由化を明記（7.3）。【その他】リスト本数を7本に訂正、閾値クリア条件を21件以上に修正、逆引きゾーン不備時ロールバック＋通知追加、インデックス列・処理規模前提（年間約200件）明記、Azure Monitorハートビート監視追加（10.4）、復旧時三者整合手順の要件化（10.5）、SegmentId＝SharePointアイテムIDと定義、StaticIpRangeRaw正本化、付録C.6（SNMP到達性・機器側設定）追加、11.3「発注条件」新設。工数35.5→39.5人日。 

1.2 

2026-07-09 

外部発注前レビュー指摘のクローズ反映（親Status集約規則・削除通知段階管理の是正・冪等性再開設計・DHCPフェールオーバー構成明記・IsActive処理規定・IT手動対応手順新設ほか） 

1.3 

2026-07-10 

設計書v1.2.1に対する質問管理表（55件）の回答確定を反映（回答済47件を反映、実値・方針の一部保留8件は次版で反映予定）。【Worker実行タイミング確定】IP払い出しWorker実行間隔を5分固定に確定（4.2/7.1）。VM/各Workerの起動時刻・タイムゾーン（JST）を確定：ARP収集=毎時00分、セグメント同期=毎時15分/45分、自動削除Worker=02:00、監視スクリプト=07:00（2.2/4.2/7.2/7.3/7.4/10.4）。【パラメータ確定】Graph API等一時エラーの指数バックオフ（初期2秒・倍率2・対象429/408/5xx/接続タイムアウト）、SNMP収集パラメータ（タイムアウト5秒・リトライ2回・並列度1）、イベントログ・ファイルログの保持設定（イベントログ512MB上書き・ファイルログ日次ローテーション90日保持）、LastSeenAtのタイムゾーン形式（JSTオフセット付きISO 8601）を確定（7.3/8.3/8.4）。SharePointアクセス障害の「継続失敗」を連続5実行サイクルに確定（10.4）。【5.2/5.4/5.5】ホスト名連番生成ボタンを実装対象外に変更（一括払い出し機能自体は存続）。拠点ドロップダウンはSitesリスト新設せずOnStartでのSegmentsコレクション化・Distinct方式に確定（データ行制限2000へ引き上げ）。確認画面の「IP」表示を削除。【データモデル確定・列追加】StaticIpRangeRaw・TargetSegmentsのJSON/格納形式を確定。ItemId列を廃止しSharePointアイテムIDを一意キーに統一。Segments.DnsServers列、ArpDeviceStatus.MerakiOrgId/MerakiNetworkId/DeviceType列、IPAMカスタムフィールドCooldownStartedAt（4項目目）、親IPRequests.CompletionNotifiedAt、明細IPRequestItems.FailureNotifiedAt・ErrorCategory（DnsDuplicate/NoFreeIp/NamingRule/SystemError/DnsDuplicateDynamicの5値）を新設（6.1/6.3/6.5/6.8/6.9）。【分岐・処理確定】RequestId決定的採番の基準を親レコードCreated（JST）に統一。空きIP候補3件枯渇時はRetryCount経由でPendingへ戻す既存経路に合流。即時Failed対象（空きIPなし/DNS重複/命名規則違反）とリトライ対象を分類。親作成後の明細部分失敗時の処理（UI側・Worker側の二重防壁）を確定。同一申請内ホスト名重複はPower Apps送信時バリデーションで排除。DNS重複チェックに動的登録レコード区分（DnsDuplicateDynamic）を追加（7.1/8.5）。ARPカバレッジ突合漏れセグメントを自動削除スキップ対象に追加。固定IP範囲縮小・消滅時の扱い（レンジ縮小反映・範囲外IPは手動判断）、DhcpScopeExists=falseセグメントのUsageCount更新責務を確定（7.2）。MissLog記録契機（申請送信時）・OfficeLocation空値の扱いを確定（5.4/7.1）。NotificationStage=Errorの書込主体を確定（7.1）。DHCPスコープ⇔Segments突合の検知対象3パターンを確定（7.2）。【セキュリティ・実装規約】SNMPはv2c標準に変更（付録E改訂、SNMPv3優先の記述を削除）。IPRequestItemsの一般ユーザ権限を確定（9.1）。Power Apps/Automate所有の共有サービスアカウントは既存E5付与済みアカウントを流用（9.2、担当チーム確認結果待ちの条件付き確定）。【契約・責任分界】「貴社」の表記を「発注元（NKC）」に全置換のうえ、11章・13章・付録Cの全作業を主体列付き責任分界表（RACI、付録G新設）として整理。Azure VM構築主体（サブスクリプション/VNet等=発注元、VM構築以降=受注側）、検証環境（本番テナント内に検証用サイト・スコープ・DNSサブゾーン）、GPO作成・Entra IDアプリ登録の管理者同意（発注元実施）、ArpDeviceStatus初期データ投入分担、Segments総件数（約1000件）を確定（2.2/9.2/10.6/11章/13章/付録C/付録G）。【受入基準】「30分以内」を努力目標（SLO）とし受入基準から除外、参考値実測報告を追加。「3名体制で継続運用可能な複雑性」は受入判定対象外とし運用手順書レビュー承認で充足とみなす。時間依存動作の受入検証は日数閾値の外部パラメータ化・下限7日ガードで確定。Entra IDユーザ単位追跡はシステム起因変更をサービスアカウント名義+RequestId/イベントログ経由の間接追跡で充足とみなす旨を注記（3.2/7.4/9.3/11.3）。【付録C】DHCPペア間スコープ定義不整合（奉賢工場172.31.140.0のEndRange）の是正結果を反映（C.1）。実値のみ保留（8件）：DNS書込先サーバ実値（FQDN）、SMTPリレー実値、C.1/C.6以外の事前調査完了時期、通知文面提供時期、PSScriptAnalyzer「重大」の対象Severity、ARP収集1サイクル実測の合格閾値、テスト観点表承認タイミング、Worker発アラートメール文面様式は、契約締結前後の別途確定事項として次版で反映する。 

1.4 

2026-07-13 

外部発注前レビュー（3-1／3-2／3-3）で抽出した38件超の指摘、および複合故障シナリオ（CC-1〜CC-8）・レース条件レビュー（5並列Worker）の結果を、確定対策仕様（05）に基づき一括反映した。【要件変更（発注元承認済み・5件）】・A-1 猶予日数の観測日数カウント：削除猶予の経過日数（1ヶ月/3ヶ月/6ヶ月/12ヶ月・Cooldown 30日）は、当該セグメントの収集経路が有効であった日数でカウントする（ARP観測が抑止されていた期間は猶予を消費しない。SkippedDays補正）。反映先＝付録B「IP登録・削除ポリシー」。・A-2 カバレッジ判定の書き分け：自動削除スキップ用の除外判定を、自動削除Workerの実行時再計算・IsActive非依存へ変更する（通知用のARPカバレッジ突合は従来どおりIsActive=trueのみを対象）。反映先＝3.1・7.4先頭処理・7.2。・A-3 初期稼働期間の削除閾値延長：既存手動設定固定IPの一括AutoDetected登録に伴う一斉Cooldown移行を回避するため、初期稼働期間はAutoDetected自動削除の日数閾値を初期延長値で運用する（外部パラメータのため実装変更不要）。反映先＝10.2・11.2・11.3・付録G。・A-4 完了通知欠落の手動回復への縮退：通知フロー最終失敗による完了通知の欠落は自動再送せず、監視スクリプトによる24時間以内の検知＋手動再送で回復する。反映先＝10.4・9.1・11.3・付録B既知の制約 項目8（E⑧）。・A-5 Cooldown実効31日：Cooldownの物理削除は「30日保持＋確認1日」で実行する（公称30日に対し実効31日）。反映先＝付録A・付録B・7.4 Cooldown満了サブフロー。【データモデル】 Segmentsに7列追加（CoverageStatus／CoverageCheckedAt／CoverageNotifiedAt／RangeChangePending／LastSkipDate／SkippedDays、およびCapacityTotal説明追記）。DnsServers定義行の誤混入行の是正：本行は履歴レコードではなくデータモデル定義行が改訂履歴表内へ物理的に誤混入したものであるため、当該行に取り消し線を付し、定義文を不変のまま6.3表（SubnetMask直後）へ移設した。IPAMカスタムフィールドにCooldownStartedAt定義行を追加（6.8）。IPRequests／IPRequestItems／ArpDeviceStatusの各列に書込主体・契機・参照先を明記（6.4/6.5/6.9）。【削除判定】 除外セグメント判定を走査開始時点の実行時再計算へ変更（IsActive非依存）。SkippedDaysによる経過日数補正を導入。Cooldown満了サブフロー（＋31日方式）を新設。7.4のIP単位述語（範囲外化IPの削除保留）を新設。スキップ解除時の緩衝を新設。復帰正典（クリア・保持フィールドの網羅列挙）を確定（7.4/7.3/10.7）。【範囲変更制御】 RangeChangePendingによる払い出し抑制・新規AutoDetected登録保留・滞留検知通知を3Worker横断で新設（7.1/7.2/7.3/10.3/5.4）。【通知】 7.4に通知フロー共通規約（フロー並列度1・送信成功確認後にガード列更新・at-least-once前提の冪等許容再送）を新設し、付録F #2/#3/#7/#8/#14/#15の契機欄を確定。NotificationStageのNotificationSentAtクリア規則を是正（6.5/7.4）。【排他・冪等】 Worker間排他（IPアドレスキーのエントリ単位ミューテックス）、ロックファイル自動失効規約、周期超過時の挙動、冪等性の総則を8.4へ新設。日数閾値の外部パラメータ化・下限7日ガードを本文化（v1.3で確定済みだが本文未反映であったものの是正。改訂履歴側の記述は履歴として正しいため非改訂）。通知抑制状態のWorkerローカル保持許容を規定（8.4・付録E）。【運用】 監視スクリプトの検知網を拡張（完了通知欠落・親Status=Pending滞留の24時間内検知／自動再送なし）。セグメント・収集機器の安全な廃止手順、代表サーバ障害中のスコープ変更規定、固定IP範囲の縮小前チェックを新設（10.3/10.4/10.6）。IT部門手動対応のCooldown元値保持義務・復帰正典参照を明記（10.7）。【文書】 付録Bに「既知の制約」一覧（10件）を新設（7.4末尾の参照先実体）。付録A用語2件、付録C調査項目2件、付録E実装規約1件、付録G責任分界2行を追加。【本版で改訂しないもの】 11.1合計行（追補行の工数値がプレースホルダのため次版で欄整備）、13章（通知文面）、付録D表本体（v1.0時点の判断経緯記録として保持）、5.4地域ドロップダウンのItems定義（v1.4対象外）。実値保留8件は引き続き次版反映とする。 

 

 

1. 本書の目的 

本書は、エンドユーザが社内Webポータル経由で固定IPアドレスを申請・取得できるシステム、および全社ネットワーク上のIPアドレス実態を自動検出・台帳化するシステムの簡易設計をまとめるものである。 

Microsoft 365 E5ライセンス範囲内でフロントエンドを構築し、Azure VM上のWindows IPAMと既存オンプレWindows DHCPを連携活用することで、追加ライセンス費用を発生させずに実装することを基本方針とする。 

本書は外部発注用の最終版であり、見積取得および設計委託の根拠資料として位置付ける。 

2. 基本方針・前提 

2.1 基本方針 

固定IP払い出しはMACバインドを使わず、従来どおり端末側での手動IP設定運用を継続する。DHCP予約は作成しない。 

Windows IPAMをIPアドレス台帳の真実の源泉（Source of Truth）とする。 

SegmentsリストをセグメントマスターのSource of Truthとする。DHCPスコープの有無にかかわらず全セグメントを管理する。 

DHCPスコープが存在するセグメントは、同期Workerが30分ごとにDHCPから除外範囲を取得し、固定IP範囲を算出してSegmentsリストに反映する。存在しないセグメントは手動値を維持する。 

ARP情報を1時間ごとに自動収集し、固定IP範囲内の未知のIP（申請外の固定設定IP）を自動検出・登録、および申請済みIPの存在確認に利用する。 

申請経由でホスト名が指定されたIPは、ホスト名ベースで社内DNS（ad.nkc.co.jp）に自動登録する。ホスト名未入力の場合はDNS登録をスキップする。 

申請外で検出されたIP（Source=AutoDetected）は1ヶ月未応答で自動削除する（削除後はCooldown 30日を経て空きプールへ復帰）。申請済みIP（Source=Requested）は段階的削除フローに従う。 

承認フローは設けない。申請送信と同時に自動払い出し処理へ進む。 

ユーザ向けの削除機能は実装しない。申請ミスや移行に伴う変更はITポータル経由でIT部門が手動対応する。 

2.2 前提環境 

Microsoft 365 E5ライセンスを全対象ユーザに付与済み。 

Entra IDを認証基盤として使用する。 

Windows DHCPサーバ4台（国内2台、海外2台）。Windows Server 2016以上。既存インフラで本プロジェクトは新設しない。 

AD統合DNS。ゾーンは ad.nkc.co.jp。逆引きゾーンはセグメントごとに設定済み。TTLは3600秒（社内統一）。 

対象ネットワーク機器のベンダー：Cisco Catalyst（IOS）、FortiGate、Yamaha RTX/NVR、Meraki MX の4系統。 

Azure VM上にWindows IPAM兼Workerサーバを1台新規構築する。社内ADドメインに参加させる。 

Azure ⇔ オンプレ間の疎通経路（VPN/ExpressRoute）は既設。社内ドメイン参加の運用実績あり。 

社内SMTPリレーサーバが利用可能であること（Worker発アラートメールの送信経路。WorkerサーバIPの許可元登録が必要。v1.1追加）。 

DHCPサーバ4台は、国内（nkdc1/nkdc2）・海外（nkdc4/nkdc5）の各ペアがDHCPフェールオーバー構成であり、スコープ定義は各ペアの両サーバに複製されている（2026年7月実査：国内455・海外10スコープの二重定義を確認）。本システムは「1セグメント=1スコープ定義」の論理前提を維持し、Segments.DhcpServerには照会先の代表サーバ（国内スコープ=nkdc1、海外スコープ=nkdc4）を登録する。パートナーサーバ（nkdc2/nkdc5）上の同一ScopeIdは処理対象としない。スコープ設定の変更は代表サーバ側で実施し、フェールオーバー複製（Invoke-DhcpServerv4FailoverReplication）でパートナーへ反映する運用とする。代表サーバ障害時はセグメント同期が停止するが、SegmentsリストとIPAMレンジは前回同期値を保持するため払い出しは継続する（v1.2追加。詳細は7.2/10.3/付録C.1参照）。 

Workerサーバから以下が到達可能であること：オンプレDHCPサーバ4台、AD統合DNS、対象NW機器（SNMP）、Microsoft Graph API、Meraki Dashboard API。 

3. 要件 

3.1 機能要件 

エンドユーザがWebポータル（Power Apps）から固定IPを申請できる。 

申請時にセグメントを、地域→拠点→セグメントの3段階カスケード選択で指定できる。各セグメントの表示はCIDRを含む。 

ホスト名・用途等を申請時に入力する。ホスト名は任意入力とし、未入力時はDNS登録をスキップする。 

MACアドレスは入力しない。ARP自動収集によって事後的に紐付ける。 

申請者情報（氏名、メール、所属、拠点）はEntra IDから自動取得する。 

申請対象は全IT機器（サーバ、プリンタ、NW機器、PC、その他）とする。 

DHCPスコープ情報（除外範囲を含む）を30分ごとに自動同期し、Segmentsマスターのうち該当するレコードを最新に保つ。 

複数ベンダーのネットワーク機器からARPテーブルを1時間ごとに取得する。 

ARPで検出されたIPのうち、固定IP範囲内（DhcpScopeExists=falseのセグメントはCIDR全体）かつIPAM未登録のものを自動的にIPAMに登録する（Source=AutoDetected）。動的プール（DHCPスコープ範囲−除外範囲）内の検出IPは登録・LastSeenAt更新の対象外とする。 

空きIPから自動で払い出し、IPAMに登録（Source=Requested）、ホスト名入力時はDNSにAレコード・PTRレコードを作成する。 

申請結果および各種通知（自動削除予告含む）を申請者へ自動通知する。退職・異動リスクを考慮し、削除関連通知は申請者の上司（Entra IDのmanager属性から取得）にも段階的に通知する。通知先の取得失敗等の異常系に限り、ネットワーク/インフラチームへ通知する。 

削除通知はWorkerがIPRequestItems.NotificationStageカラム（明細単位）を更新し、Power AutomateがNotificationStage列の変化をトリガに、値に応じたテンプレートで通知送信する（案B採用）。同一申請・同一段階の明細は集約して1通で送信し、NotificationSentAt列で送信済みを管理する。 

一定期間ARPで応答がないIPを、区分に応じて自動削除する。Cooldown期間中のIPおよびCooldown満了時の物理削除も、削除スキップ（Failed機器由来・未カバー由来のカバレッジ保護）の適用対象に含める（詳細は7.4）。自動削除実施時にIPRequestItems.Status=Archivedを設定し履歴を保持する（全明細がArchivedとなった時点で親IPRequestsもArchivedとする）。（v1.4差替え） 

申請送信時にOfficeLocationMapで未マッチだった場合（OfficeLocation空値を含む）、MissLogへ記録する。OfficeLocation値ありの未マッチのみ、ネットワーク/インフラチームへ即時メール通知する（空値は記録のみで即時通知対象外。v1.3確定）。 

1申請で同一セグメント内の複数IPを一括払い出しできる（最大20件）。一部失敗時は成功分を確定し、失敗分はFailed扱いとする（部分成功を許容）。 

セグメントごとの空きIP数が20件以下になった場合、ネットワーク/インフラチームへメール通知する（通知先：nkis-network@nkc.co.jp）。閾値を下回り続けている間は1日1回通知する（AlertLastNotifiedAtで重複抑制）。閾値チェックは全セグメント（DhcpScopeExists問わず）を対象とする。 

DHCPスコープ⇔Segmentsリスト突合チェックをセグメント同期Worker実行時に実施し、漏れ検知時はnkis-networkへ通知する。検知対象は(a)スコープ実在だがSegments未登録、(b)DhcpScopeExists=trueだがスコープ実体なし、(c)CIDR不一致、の3パターンとする（v1.3確定）。 

ARPカバレッジ突合チェック（IsActive=trueの全SegmentsのCIDRがいずれかのArpDeviceStatus.TargetSegmentsに含まれること）をセグメント同期Worker実行時に実施し、漏れ検知時はnkis-networkへ通知する（同一内容の通知は1日1回まで。v1.1追加）。 

IsActive=falseセグメントの取扱いを明確化する（v1.2追加）：申請UI表示・新規AutoDetected登録・空きIP閾値チェック・ARPカバレッジ突合は対象外とする一方、既存登録IPのLastSeenAt更新（判定条件はIPAM登録済みかつ動的プール外のみとしIsActiveは条件に含めない）と自動削除は対象に含める（稼働中IPの誤削除防止と不要IPの回収を両立）。IPAMレンジはIsActive=false化後も削除しない。登録側の除外は7.3の分岐(c)で実装する。既存登録IPのLastSeenAt更新およびCooldown復帰はIsActive非依存で継続する（登録と更新の非対称は、誤削除防止のための意図的な設計である）。（v1.4追加） 

ARP収集機器の状態をArpDeviceStatusリストで管理する。72時間連続失敗でFailed遷移通知をnkis-networkへ送信し、Failed機器担当セグメントは自動削除スキップを行う。ARPカバレッジ突合チェックで検知した未カバーセグメント（いずれのArpDeviceStatus.TargetSegmentsにも含まれないセグメント）も、Failed機器担当セグメントと同様に自動削除スキップ対象とする（v1.3確定）。自動削除スキップ用の除外判定は、自動削除Workerが実行時にIsActive値によらず全セグメントを対象として行う（走査開始時点の実行時再計算。7.4先頭処理）。一方、通知用のARPカバレッジ突合（1日1回）は従来どおりIsActive=trueのセグメントのみを対象とする（7.2）。（v1.4追加。要件変更＝A-2） 

3.2 非機能要件 

追加ライセンス費用を発生させない。Microsoft 365 E5に含まれるPower Apps for Microsoft 365 / Power Automate for Microsoft 365（Standard connectorsのみ）/ SharePoint / Entra ID の範囲内で実装する。ただしAzure Backupのストレージ従量課金およびAzure VMの稼働課金は本システム運用コストとして別途発生する。なお、運用上の必要に応じて、Power Apps / Power Automateの所有者となる共有サービスアカウント（1アカウント）へのライセンス付与は検討可能とする。 

3名体制で継続運用可能な範囲の複雑性とする。本要件は受入判定対象から除外し、運用手順書・マスタメンテ手順の発注元レビュー承認をもって充足とみなす（v1.3確定）。 

処理規模の前提（v1.1追加）：年間申請件数 約200件、AutoDetectedの定常的な新規検知 約10件/年（非正規IP）。ただし初期稼働時は既存の手動設定固定IPが一括でAutoDetected登録される（既存固定IPの台帳化を意図した挙動）。本規模ではSharePointリストの5000件閾値到達まで10年以上を要するため、リスト分割・アーカイブ設計は初期スコープ外とする。 

申請からIPAM登録・DNS登録完了まで、管理者介在なしで30分以内を目標とする。本目標値は努力目標（SLO）とし受入基準から除外する。参考値として、単件申請・20件一括申請の2ケースの実測を受入時に報告する（v1.3確定）。 

全申請・全変更の履歴をEntra IDユーザ単位で追跡可能とする。システム（Worker/Power Automate）起因の変更はサービスアカウント名義で記録されるが、RequestId・イベントログ経由で申請者へ間接的に追跡可能であることをもって本要件の充足とみなす（v1.3確定。9.3参照）。 

既存の手動IP設定運用と共存可能であること（端末側の設定変更を強制しない）。 

3.3 スコープ外 

承認フロー（申請即自動処理とする）。 

ユーザ向けの削除機能（ITポータル経由の手動対応とする）。 

利用期間指定（終了予定日）。全申請を恒久扱いとする。 

ホスト名変更・DNS切替（IT部門の手動対応）。 

サーバ移行に伴うIP事前確保（IT部門の手動対応）。 

DHCPスコープの新規作成・変更およびスコープ命名規則の整備（既存運用に準拠）。 

ネットワーク機器台帳（DCIM）としての利用（本システムはIPAM用途に限定）。 

802.1Xなどの認証基盤連動。 

IPv6対応（将来拡張）。 

多言語切替対応（将来拡張）。UI言語は日本語を基本とする。表示名カラム（SegmentName、SiteName等）は後日の日英併記化を想定した命名としている。 

NKSVのCNAMEホスト名（特殊ホスト名）のDNS登録（手動対応）。 

Windows以外の端末設定ガイドの作成（ユーザ側で各自対応する運用を継続）。 

4. 全体アーキテクチャ 

4.1 構成要素 

区分 

コンポーネント 

役割 

備考 

クラウド（M365） 

Power Apps 

エンドユーザ向け申請UI 

E5標準 

クラウド（M365） 

SharePointリスト（7本） 

申請台帳・マスターデータ保持 

詳細は6章（ArpDeviceStatus追加） 

クラウド（M365） 

Power Automate 

申請受付・通知・MissLog通知・NotificationStage連動通知 

Standard connectorsのみ使用 

クラウド（M365） 

Entra ID 

ユーザ認証・属性提供 

既存テナント利用 

クラウド（Azure） 

Azure VM（IPAM兼Worker） 

Windows IPAM本体と全Workerを同居 

4vCPU/16GB、社内AD参加 

クラウド（Azure） 

Azure Backup（MARS） 

IPAM+Workerサーバの日次バックアップ 

Recovery Services vault 

オンプレ 

Windows DHCP 4台 

DHCP動的配布（予約は作らない） 

既存構成・既存バックアップ体制 

オンプレ 

AD統合DNS 

DNSレコード管理 

既存構成、ad.nkc.co.jp 

オンプレ 

NW機器（Cisco/Fortinet/Yamaha/Meraki） 

ARP収集元 

SNMPまたはAPI 

4.2 Worker一覧 

Worker名 

言語 

実行頻度 

主な処理 

IP払い出しWorker 

PowerShell 

5分固定（v1.3確定） 

Pending案件検出→IPAM登録→DNS登録（ホスト名ありの場合）→SharePoint更新・Processing滞留回収。範囲変更中セグメントの払い出し抑制・サイクル先頭の親集約修復（v1.4追加） 

セグメント同期Worker 

PowerShell 

30分ごと（毎時15分/45分起点。v1.3確定） 

DHCPスコープ情報をSegmentsリストへ同期・空きIP閾値チェック・DHCPスコープ⇔Segments突合チェック・IPAMレンジ同期・ARPカバレッジ突合チェック。範囲変更検知・RangeChangePending管理・カバレッジ判定書込（v1.4追加）【括弧書き削除：(g)-4】 

ARP収集Worker 

Python＋PowerShell（IPAM反映部） 

1時間（毎時00分起点。v1.3確定） 

全NW機器からARP取得・IPAM登録/更新・ArpDeviceStatusリストをUpsert更新 

自動削除Worker 

PowerShell 

日次（深夜）（02:00起点。v1.3確定） 

LastSeenAtベースで段階的削除・NotificationStage更新・ArpDeviceStatus参照によるスキップ制御。除外の実行時再計算・SkippedDays記録・Cooldown満了サブフロー（v1.4追加） 

※ セグメント同期Worker実行頻度：v1.2の「日次（深夜）」を「30分ごと」に修正（5.3節既知論点の反映）。 

※ Azure VMはJSTタイムゾーン設定とする。監視スクリプトは07:00起点で日次実行する（v1.3確定）。 

4.3 責務分界 

Windows IPAMの役割 

全IPアドレスの真実の源泉。申請経由・自動検出を問わず、あらゆるIPを一元管理。 

空きIP検索・払い出し判定のエンジン。 

DHCPスコープ情報との連携（IPAM連携機能）。 

SharePointリストの役割 

Segmentsリストはセグメントマスターの一次情報源（DHCPスコープ非存在セグメントも含む）。 

IPRequestsは申請ワークフローの受付台帳。 

ArpDeviceStatusはARP収集機器のステータス管理台帳。 

Power AppsのUIデータソース（Regions、Segments、OfficeLocationMap）。 

申請者情報・ワークフローメタデータの保持。 

IPAM登録後の申請履歴としての意味合いで残る。 

4.4 論理構成イメージ 

[ エンドユーザ ] → Power Apps → SharePointリスト（M365） 

↓↑ (Graph API, HTTPS) 

[ Azure VM: Windows IPAM + Worker群 ] ← (VPN/ExpressRoute) → オンプレ 

├ Windows IPAM（本体） 

├ IP払い出し/同期/自動削除Worker（PowerShell） 

└ ARP収集Worker（Python）（収集結果はPowerShell反映スクリプトでIPAMへ登録） 

↓↑ 

[オンプレ] Windows DHCP 4台 / AD統合DNS / NW機器（SNMP/API） 

5. 画面設計（Power Apps） 

5.1 画面一覧 

申請入力画面：固定IP申請を入力する主画面。 

確認画面：入力内容の最終確認と送信。 

申請履歴画面：ログインユーザ自身の過去申請を閲覧。 

管理者画面（オプション）：管理者が全申請を横断閲覧・介入。初期実装ではSharePointリストのビューで代替。 

5.2 申請入力画面の項目 

項目 

入力方式 

必須 

備考・バリデーション 

地域 

ドロップダウン 

必須 

都道府県/国単位。OfficeLocationMapから初期値推定。手動変更可 

拠点 

ドロップダウン 

必須 

地域で絞り込み 

セグメント 

Combobox 

必須 

拠点で絞り込み。CIDRを併記表示 

ホスト名 

テキスト 

任意 

入力時のみ正規表現でバリデーション。DNS登録に使用。未入力時はDNS登録スキップ。Worker側で重複チェック 

用途説明 

テキストエリア 

必須 

何の機器か（200文字以内） 

※ MACアドレスは申請入力項目に含めない。ARP自動収集によって事後的に紐付ける方式とする。 

※ 一括払い出し対応：ホスト名・用途説明は明細行単位で入力する（最大20行）。ホスト名連番生成ボタンは実装しない（v1.3確定。一括払い出し機能自体は存続し、ホスト名は明細行ごとに手入力とする）。 

※ 申請入力画面の上部（入力フォームの直上）に注意事項バナーを表示する。表示内容：「ホスト名を入力しない場合、DNS登録は行われません。必要な場合は命名規則（NKSV/NKNODE/PCD/PCM/PCS/PRT + 数字）に従って入力してください。」 

※ 申請入力画面の下部（送信ボタン上部）に案内エリアを設ける。表示内容（固定テキスト＋リンク）：(1)特定のIPアドレスを指定して払い出してほしい場合はITポータルから申請。(2)申請内容の変更・削除はITポータルから申請。(3)ホスト名変更・DNS切替はITポータルから申請。(4)申請ミス・移行対応のご相談はITポータルへ。(5)よくある質問（FAQページへのリンク、URLは実装時に確定）。実装方式：Power AppsのLabelコントロール＋Hyperlink関数で静的表示。 

5.3 バックグラウンドで自動取得する情報 

申請者UPN（ユーザプリンシパル名） 

申請者氏名（表示名） 

申請者メールアドレス 

所属部署（Department） 

所属拠点（OfficeLocation）- 地域・拠点初期値推定に使用 

上司（Manager）- 削除関連通知で使用 

申請日時（タイムスタンプ） 

5.4 3段カスケードドロップダウンの実装 

地域→拠点→セグメントの3段カスケードを、Power Apps標準関数およびOfficeLocationMapで実装する。 

拠点マスター用のSitesリストは新設しない（SharePointリストは7本のまま）。拠点ドロップダウンはOnStartでSegmentsをコレクション化しSiteCodeでDistinct・SiteName表示とする。Power AppsのSegmentsデータ行制限は2000へ引き上げる（Segments総件数は約1000件を想定）。表示順はSiteName順とし、SiteNameの表記ゆれは運用注意事項とする（v1.3確定）。 

【初期値推定】 

LookUp(OfficeLocationMap, OfficeLocation = User().OfficeLocation) の結果から、RegionCodeとSiteCodeを取得し初期値に設定する。未マッチ時は未選択のまま（OfficeLocationMissLogへ記録）。 

【セグメントCombobox】 

Items: Filter(Segments, SiteCode = DropdownSite.Selected.SiteCode && IsActive = true && RangeChangePending = false) 

RangeChangePending=trueのセグメントは選択肢から除外する（申請流入の補助抑制。一次抑制はWorker側＝7.1による）。（v1.4差替え） 

Comboboxテンプレートで Primary Text=SegmentName、Secondary Text=CIDR の2行表示とする。 

5.5 確認画面仕様 

確認画面でホスト名・セグメント（CIDR併記）を大きなフォントで目立つ表示とする（申請送信後にWorkerが払い出すため送信前時点でIPは未確定。「IP」表示は削除。v1.3確定）。 

「このホスト名で間違いありませんか?」のチェックボックスを必須化（未チェックでは送信不可）。 

「申請後の修正はITポータルへの依頼が必要です」の警告メッセージを常時表示。 

一括払い出し時は明細一覧（件数・ホスト名・用途）を確認画面に表示する。 

ホスト名未入力の場合、「DNS登録は行われません」を明示表示。 

6. データモデル 

6.1 構成 

データはSharePointリスト7本と、Windows IPAMカスタムフィールド4項目で保持する。責務は4.3節参照。 

SharePointリスト7本: Regions、Segments、IPRequests、IPRequestItems、OfficeLocationMap、OfficeLocationMissLog、ArpDeviceStatus 

Windows IPAMカスタムフィールド4項目: Source（Cooldown値追加）、RequestId、LastSeenAt、CooldownStartedAt（v1.3新設。Cooldown起算点の保持用） 

以下の列はSharePointのインデックス列として作成する（クエリ・Power Apps委任対策。v1.1追加）：IPRequests.Status／RequesterUpn、IPRequestItems.Status／ParentItemId／AssignedIp。Segments.SiteCode／RegionCodeもインデックス列とする（v1.3追加。Q45対応）。 

※ v1.0でIPRequestItemsおよびArpDeviceStatusを追加しており、SharePointリストは計7本である（「6本」は誤記のため訂正）。 

6.2 Regions（地域マスター） 

列名 

型 

説明 

RegionCode 

1行テキスト 

地域コード（例：saitama、gunma、usa） 

RegionName 

1行テキスト 

表示名（例：埼玉、群馬、米国） 

DisplayOrder 

数値 

ドロップダウン表示順 

IsActive 

はい/いいえ 

有効フラグ 

6.3 Segments（セグメントマスター） 

セグメントマスターの一次情報源。DHCPスコープの有無にかかわらず全セグメントを登録する。DhcpScopeExists=trueのレコードのみ同期Workerが30分ごとに更新する（ただしUsageCount・CapacityTotal・カバレッジ由来項目は7.2の各更新規定に従い、DhcpScopeExists値によらず更新対象となる場合がある）。（v1.4差替え） 

列名 

型 

説明 

SegmentName 

1行テキスト 

論理名（例：富岡生産センタ - サーバセグメント） 

SiteCode 

1行テキスト 

拠点コード（例：tomioka-seisan） 

SiteName 

1行テキスト 

拠点表示名（例：富岡生産センタ） 

RegionCode 

1行テキスト 

地域マスターへの参照 

CIDR 

1行テキスト 

CIDR表記（例：10.11.20.0/24） 

DhcpScopeExists 

はい/いいえ 

DHCPスコープの有無フラグ 

DhcpScopeName 

1行テキスト 

DHCPスコープ名（DhcpScopeExists=true時のみ） 

DhcpServer 

1行テキスト 

照会先の代表DHCPサーバのFQDN（国内=nkdc1、海外=nkdc4。パートナーサーバは対象外。v1.2修正） 

StaticIpRangeStart 

1行テキスト 

固定IP範囲の先頭 

StaticIpRangeEnd 

1行テキスト 

固定IP範囲の末尾 

StaticIpRangeRaw 

複数行テキスト 

固定IP範囲のJSON表現（複数レンジ対応）。固定IP範囲の正本はこの列とする（StaticIpRangeStart/Endは代表レンジの表示用） 

Gateway 

1行テキスト 

デフォルトゲートウェイ（申請者通知用） 

SubnetMask 

1行テキスト 

サブネットマスク（申請者通知用） 

DnsServers 

複数行テキスト 

DNSサーバ一覧（改行区切り、優先/セカンダリ）。スコープ有りはDHCPオプション006から同期、スコープ無しは手動値（Gateway/SubnetMaskと同一の管理パターン）。完了通知への記載に使用（v1.3新設）　※本行は改訂履歴表からの移設（定義文は不変。v1.4移設） 

UsageCount 

数値 

固定IP範囲内の使用IP数（IPAMから同期）。最大30分のタイムラグを許容する。 

CapacityTotal 

数値 

固定IP範囲の総IP数。DhcpScopeExists=falseセグメントは、CIDR全体（ネットワークアドレス／ブロードキャストアドレス／Gateway予約を除く）からWorkerが算出する（7.2）。（v1.4追加） 

Description 

1行テキスト 

用途説明 

IsActive 

はい/いいえ 

有効フラグ。CIDR変更は禁止：変更不可・必要時はレコード新規作成＋旧IsActive=false。 

LastSyncedAt 

日時 

最終同期日時 

AlertLastNotifiedAt 

日時 

空きIP閾値アラートの最終通知日時。重複通知抑制に使用。空きIP数が21件以上に回復した際にクリアする。 

CoverageStatus 

選択肢 

ARPカバレッジ突合結果（Covered/Uncovered）。IsActive=trueセグメントを対象に、同期Workerが実行のたびに判定・更新する（7.2）。用途は通知抑制・運用可視化・監査であり、自動削除の除外判定には使用しない（7.4は走査開始時点の実行時再計算による）。既定値は空（初回の同期Worker実行で設定される）。v1.4新設 

CoverageCheckedAt 

日時 

CoverageStatusの最終判定時刻（7.2）。既定値は空。v1.4新設 

CoverageNotifiedAt 

日時 

ARPカバレッジ漏れ通知の最終送信日時。同一内容の通知を1日1回に抑制するために使用する（7.2・3.1）。CoverageStatusがCoveredへ回復した際にクリアする。既定値は空。v1.4新設 

RangeChangePending 

はい/いいえ 

固定IP範囲の変更（除外範囲変更・CIDR入替）がDHCP側で実施され、IPAMへの反映および（拡張時の）ARP台帳化が未完了である状態を示すフラグ。ネットワーク/インフラチームが変更作業前にtrueを設定し（10.3）、同期Workerもレンジ変更検知時にセーフティネットとしてtrueを設定する（7.2）。falseへの復帰は7.2の解除規定（拡張・縮小・入替を覆う）による。true期間中は当該セグメントの新規払い出しを抑制し（7.1）、新規AutoDetected登録を保留する（7.3）。範囲外化したIPの削除保護は本フラグではなく7.4のIP単位述語による。既定値は「いいえ（false）」とする。v1.4新設 

LastSkipDate 

日時 

当該セグメントが自動削除評価のスキップ対象となった最終適用日。自動削除Workerが書込（7.4先頭処理）。スキップ解除時の緩衝における「解除後最初の実行」判定に使用。既定値は空。v1.4新設 

SkippedDays 

数値 

自動削除評価がスキップされた日数の累積。自動削除Workerがスキップ適用日に+1する（加算対象はFailed機器由来・未カバー由来のセグメント単位事由のみ。IP単位のレンジ非所属事由は加算しない）。経過日数算定およびCooldown満了述語の補正項として使用する（7.4・6.8の日数計算規約）。既定値は0（未設定は0として扱う。Segments初期投入時も0を投入する）。v1.4新設 

※ 本表への列追加はv1.4において7列追加＋1列移設（DnsServers）で打ち止めとする。代表DHCPサーバ照会失敗通知（7.2）の1日1回抑制は、6.3への列追加を行わずWorkerローカル保持とする（規定は8.4）。 

6.4 IPRequests（申請台帳） 

列名 

型 

説明 

RequestId 

1行テキスト 

一意ID。REQ-yyyymmdd-{親アイテムID}の決定的採番とする（連番カウンタ不使用のため同時申請でも衝突しない。例：REQ-20260421-1052）。一括払い出し時は複数のIPRequestItemsレコードと紐付く。 

RequesterUpn 

1行テキスト 

申請者UPN 

BatchSize 

数値 

申請明細件数（1〜20） 

RequesterName 

1行テキスト 

申請者氏名 

RequesterEmail 

1行テキスト 

申請者メール 

Department 

1行テキスト 

所属部署 

OfficeLocation 

1行テキスト 

所属拠点 

SegmentId 

1行テキスト 

選択したSegmentsレコードのSharePointアイテムID 

Status 

選択肢 

Pending/Assigned/PartiallyFailed/Failed/Archived（Processingは明細のみで使用）。一括払い出し時に一部成功・一部失敗の場合はPartiallyFailed。全明細がArchivedとなった時点でArchived（I-10対応。v1.1で明細単位管理へ変更）。※Rejectedは廃止（承認フローなし・発生経路なし）　Archivedへの集約更新は自動削除Workerが実施する（7.4）。（v1.4追加） 

ProcessedAt 

日時 

処理完了日時。IP払い出しWorkerが親Status集約更新と同一PATCHで書き込む。Power Appsが親作成時にnullで初期化する（7.1）。（v1.4追加） 

CompletionNotifiedAt 

日時 

完了通知（#2）の送信済み管理（v1.3新設）。未設定のみ送信・送信後に更新。Power Automateが親Status変化トリガの多重発火防止に使用　Power Appsが親作成時に未設定で初期化する。送信は7.4の通知フロー共通規約（フロー並列度1・送信成功確認後にガード列を更新）に準拠する。（v1.4追加） 

ErrorMessage 

複数行テキスト 

失敗時のエラーメッセージ。書込主体はProcessedAtと同一（同一PATCH）。ただしUI側防壁による親Failed確定時はPower Appsが書き込む（7.1）。（v1.4追加） 

【注意】HostName/Purpose/AssignedIp/AssignedFqdnは一括払い出し対応により子リスト（IPRequestItems）へ移動済み。単件申請時も子リストに1件作成する。 

6.5 IPRequestItems（申請明細リスト） 

一括払い出し対応のため申請明細を保持する。1件申請時も本リストに明細1件を作成する。削除通知の段階管理（NotificationStage）は本リスト（明細）単位で行う（v1.1変更）。 

列名 

型 

説明 

 

 

列廃止（v1.3確定）。SharePointアイテムIDを一意キーの正とする。 

ParentItemId 

数値 

親IPRequestsのSharePointアイテムID（参照キー）。表示用のRequestIdは親レコードから参照する 

HostName 

1行テキスト 

ホスト名（任意、未入力時はnull） 

Purpose 

複数行テキスト 

用途説明 

Status 

選択肢 

Pending/Processing/Assigned/Failed/Archived（v1.1追加：12ヶ月削除時に設定） 

RetryCount 

数値 

明細行単位のリトライ回数。プロセス内一時エラー起因のサイクル跨ぎ再処理と、Processing滞留回収（7.1）による加算を同一カウンタへ合算し、経路を問わず上限3回で終端する。（v1.4追加） 

NotificationStage 

選択肢 

削除通知段階管理（v1.1でIPRequestsから移動）。値：None / 3M-Reminder / 6M-Reminder / 12M-Deleted / Error。Power Automateがこのカラムの変化をトリガに集約通知を送信。段階遷移時、NotificationSentAtが未設定の明細に限り同一更新内でクリア（未設定維持）する。Error状態からの復帰上書きに限り、送信済み明細のSentAtを保持する（詳細規則および冪等タッチ（再駆動）は7.4を正とする）。（v1.4差替え） 

NotificationSentAt 

日時 

集約通知の送信済み管理（v1.1新設）。Power Automateが送信完了後に更新。未設定の明細のみが集約対象。更新は送信成功確認後に行う（7.4の通知フロー共通規約）。（v1.4追加） 

AssignedIp 

1行テキスト 

払い出されたIP（Worker書き込み） 

AssignedFqdn 

1行テキスト 

登録FQDN（ホスト名ありの時のみ） 

ProcessedAt 

日時 

処理完了日時 

FailureNotifiedAt 

日時 

失敗通知（#3）の送信済み管理（v1.3新設）。未設定のみ送信・送信後に更新（NotificationSentAtと同一パターン）。フロー並列度は1とし、7.4の通知フロー共通規約に準拠する。（v1.4追加） 

ErrorCategory 

選択肢 

失敗原因の区分。値：DnsDuplicate/NoFreeIp/NamingRule/SystemError/DnsDuplicateDynamic（動的登録レコード起因）。Workerが設定し、Power Automateのメッセージ選択に使用（v1.3新設）　設定契機の一覧は7.1の集約注記を正とする。UI側防壁によるFailed確定時はPower Appsが設定する。（v1.4追加） 

ErrorMessage 

複数行テキスト 

失敗時のエラーメッセージ 

6.6 OfficeLocationMap（OfficeLocation変換マスター） 

列名 

型 

説明 

OfficeLocation 

1行テキスト 

Entra IDのOfficeLocation値（マッチキー） 

RegionCode 

1行テキスト 

対応する地域コード 

SiteCode 

1行テキスト 

対応する拠点コード 

IsActive 

はい/いいえ 

有効フラグ 

Note 

1行テキスト 

メモ（旧表記・統合元など） 

6.7 OfficeLocationMissLog（未マッチログ） 

列名 

型 

説明 

DetectedAt 

日時 

検出日時 

OfficeLocation 

1行テキスト 

未マッチだったOfficeLocation値 

RequesterUpn 

1行テキスト 

申請者UPN 

Resolved 

はい/いいえ 

対応済みフラグ（ネットワーク/インフラチームが更新） 

※ BatchSizeカラムはMissLogが申請1件=1レコードのため不要として削除（I-6対応）。 

6.8 Windows IPAMカスタムフィールド 

フィールド名 

型 

用途 

Source 

マルチバリュー 

Requested/AutoDetected/Cooldown。自動削除ポリシー・DNS登録要否の判定に使用。Cooldownはクールダウン期間中のIP保持に使用。Cooldown移行時は元のSource値に追加付与する（マルチバリュー）。Cooldown値の付与時はCooldownStartedAtを同時に設定する（本表参照）。（v1.4追加） 

RequestId 

フリーフォーム 

SharePoint申請台帳との紐付けキー。AutoDetectedでは空（明細単位の払い出しでは「REQ-yyyymmdd-{親アイテムID}-{明細アイテムID}」を格納する。SharePoint側IPRequests.RequestIdは親単位の採番のまま変更しない。v1.2変更）。自動削除Worker（7.4）は本値から明細アイテムIDを抽出してIPRequestItemsを逆引きする（7.4の明細特定規定を参照）。（v1.4追加） 

LastSeenAt 

フリーフォーム 

最終ARP応答日時（ISO 8601形式）。JSTオフセット付きISO 8601（例：2026-07-03T14:00:00+09:00）で格納。削除判定はJST変換後の日付差で日数計算する（v1.3確定）。払い出し成功時は払い出し日時で初期化する（未応答IPの起点定義。v1.1）。自動削除判定に使用 

CooldownStartedAt 

フリーフォーム 

Cooldown移行日時（起算点）。JSTオフセット付きISO 8601（例：2026-07-03T02:15:00+09:00）で格納。SourceへのCooldown値追加付与と同一更新内で設定する。Cooldown満了物理削除の判定起算に使用（判定式・実行主体は7.4のCooldown満了サブフローを参照）。復帰時（自動復元・IT部門の手動復帰とも）に必ずクリアする。v1.4新設 

※ 経過日数の計算規約（全削除判定共通）：LastSeenAt・CooldownStartedAtからの経過日数は、JST変換後の日付差で算出する。閾値判定は「経過日数 ≥ 閾値」（閾値当日を含む）とする。経過日数の算定にあたっては、当該セグメントのSkippedDays（6.3）を日付差から減じる（凍結期間は猶予を消費しない。AutoDetected 30日・Requested 90/180/365日・Cooldown満了のすべてに共通適用。要件変更＝A-1。補正の定義は本項（6.8-2）を正典とする）。（v1.4追加・v1.4追記） 

6.9 ArpDeviceStatus（ARP収集機器ステータスリスト） 

ARP収集機器の状態管理リスト（v1.0新設）。ARP収集Workerが機器処理ごとにUpsert更新する。 

本リストはARP収集対象機器のマスターを兼ね、Workerは本リストから対象機器を取得する（機器行の追加・廃止・TargetSegments変更はネットワーク/インフラチームが実施。10.6参照。v1.1追記）。 

VRRP/HSRP等の冗長ゲートウェイは代表1台のみ登録し、待機系は登録しない。代表機障害時はARP検知の停止を許容する（72時間連続失敗検知→該当セグメントの自動削除スキップで保全。v1.1確定）。 

列名 

型・説明 

DeviceId 

1行テキスト 機器一意ID（例：cisco-cat-tomioka-01） 

DeviceName 

1行テキスト 機器名（表示用） 

DeviceFqdn 

1行テキスト FQDN（ARP収集時の接続先） 

DeviceType 

選択肢 収集方式・ベンダー判別用（CiscoIOS/FortiGate/YamahaRTX/MerakiMX）。v1.3新設　ARP収集Workerの収集方式分岐の駆動キーである（7.3）。未設定または定義外値の機器は収集をスキップし、失敗として計上する（7.3）。機器行追加時の初期値投入は必須とする（10.6・付録C.6）。（v1.4追加） 

MerakiOrgId 

1行テキスト Meraki組織ID。台帳・運用参照用の記録項目であり、7.3の収集処理では参照しない（収集はMerakiNetworkIdのみを使用する）。（v1.4用途明確化） 

MerakiNetworkId 

1行テキスト MerakiネットワークID（Meraki機器のみ使用、1機器=1ネットワークとして登録）。v1.3新設　7.3のMeraki収集において /networks/{MerakiNetworkId}/clients の呼び出しに使用する。（v1.4追加） 

TargetSegments 

複数値テキスト 当該機器が担当するCIDRの一覧（正引き方式） 

LastSuccessAt 

日時 直近ARP収集成功時刻 

LastAttemptAt 

日時 直近ARP収集試行時刻 

ConsecutiveFailureCount 

数値 連続失敗回数（成功時に0リセット） 

CurrentStatus 

選択肢 OK / Failed 

LastErrorMessage 

複数行テキスト 直近エラー詳細 

LastNotifiedAt 

日時 通知重複抑制用（最終通知日時） 

7. 処理フロー 

7.1 申請受付〜払い出しフロー 

ユーザがPower Appsにアクセスし、Entra ID認証完了。 

申請フォームを入力・送信。Power AppsがIPRequestsリストに新規レコード作成（Status=Pending）。Patch戻り値から親アイテムIDを取得し、IPRequestItemsに明細を作成する（ParentItemId=親アイテムID、Status=Pending、NotificationStage=None、NotificationSentAt=空で初期設定）。FailureNotifiedAtも空（未設定）で作成する。親IPRequests作成時、CompletionNotifiedAtも空とする（未設定＝未送信を各通知フローの送信済み判定に用いる）。（v1.4追加） 

Power AutomateがRequestIdを設定（REQ-yyyymmdd-{親アイテムID}の決定的採番）し、申請受付メールを送信。採番遅延が払い出しをブロックしないよう、Workerは同式でRequestIdを導出可能とする。yyyymmddの基準日時は親レコードのCreated（JST変換後の日付）に統一する。Power Automate設定値とWorker導出値は同一入力から導出するため定義上不一致は発生しない（発生時はバグとして扱う。v1.3確定）。 

OfficeLocationMapで未マッチだった場合、MissLogリストにレコード追加（別フロー経由で即時通知）。MissLogへのレコード追加は申請受付フロー（Power Automate。付録F#8のトリガ元）が実施する（Power Apps側は検知のみ）。（v1.4追加） 

Workerは各サイクルの先頭で、Pending明細の取得に先立ち、親Status=PendingかつBatchSize分の全明細が終端状態（Assigned/Failed）に達している親レコードを検索し、親Statusの集約更新を実行する（クラッシュ等で最終明細の終端書込後・親集約前に処理が中断した断面の自己修復。集約規則どおりの値を書くのみの冪等操作であり、同一PATCH規定に従う）。（v1.4新設ステップ） 

IP払い出しWorkerが5分毎（v1.3確定。4.2と一致）にSharePointを監視し、IPRequestItems.Status=Pendingの明細を取得（親はParentItemIdで結合）。処理は明細駆動とし、親Statusは明細の集約結果として更新する。 

取得した明細のうち、対象セグメントのRangeChangePending=trueの明細は、Pendingのまま当サイクルでは処理をスキップする（RetryCountは加算せず、Processing滞留回収〔30分〕の対象にも含めない）。抑制中の滞留はRangeChangePending滞留通知（7.2）が検知する。UI側（5.4）の申請流入抑制は補助と位置付ける。（v1.4新設ステップ） 

Workerが明細StatusをProcessingに更新（ロック）。Worker多重起動防止のため、ミューテックスまたはロックファイル方式を実装すること。 

Processingのまま最終更新から30分以上経過した明細は滞留と見なし、Pendingへ戻してnkis-networkへ警告通知する（Workerクラッシュ時の回収。v1.1追加）。 

Pendingへ戻す際、当該明細のRetryCountをインクリメントする（加算はプロセス内一時エラーリトライと同一のRetryCountへ合算し、加算経路を問わず上限3回で終端する）。RetryCount≧3に達した滞留明細はPendingへ戻さずStatus=Failed確定とする。Failed確定時は、明細単位キー（REQ-yyyymmdd-{親アイテムID}-{明細アイテムID}）でIPAMを検索し、既登録エントリが存在する場合はIPAMロールバック（DNS登録済みの場合はDNSレコード削除を含む）を実施してからFailed確定する（ロールバック失敗時はnkis-networkへ緊急アラート〔既存経路〕）。あわせてErrorCategory=SystemErrorを設定し、FailureNotifiedAt経由の失敗通知（付録F#3）が既存経路で発火する。（v1.4追加） 

Workerがホスト名の有無で分岐処理を実行（明細行ごとにループ、最大20件）。 

Workerは処理開始時にホスト名の命名規則を再検証する（SharePoint直接編集等のPower Apps外経路に備えた防御的チェック。違反時は明細Status=Failed・命名規則エラー文面で通知。v1.1で復活）。 

リトライは2層構成とする。(1) 一時エラー（Graph API等）はプロセス内で指数バックオフにより最大3回リトライ（RetryCountは増やさない）。(2) サイクル跨ぎの再処理時に明細のRetryCountをインクリメントし、RetryCount≧3で明細Status=Failed確定＋nkis-networkへエスカレーション通知。失敗時はIPAMロールバック→明細Status=Pending→次サイクル再処理。IPAMロールバック失敗時はnkis-networkへ緊急アラート送信。 

成功時はIPAM登録と同時にLastSeenAt=払い出し日時を初期設定のうえ、IPRequestItems.Status=Assigned、AssignedIp、AssignedFqdn（ホスト名ありの時のみ）、ProcessedAtをSharePointに書き込み。払い出し完了通知メール本文には「通知された新IPに手動設定変更」を明記する（AutoDetected重複時の運用ガイド）。 

親IPRequests.Statusの集約更新は、全明細が終端状態（AssignedまたはFailed）に達した時点でのみ実施する（全件Assigned=Assigned／混在=PartiallyFailed／全件Failed=Failed）。PendingまたはProcessingの明細が1件でも残る間は親Statusを更新せずPendingを維持する（リトライ中明細を含む申請への完了通知の誤発火・二重発火防止）。終端値設定後の親Statusの再遷移はArchivedへの遷移以外行わない。 

親IPRequestsのStatus集約更新は、ProcessedAt・ErrorMessageと同一PATCHで書き込む（Power Automateトリガの発火回数を抑制する。ただし多重発火の防止自体は通知フロー側の並列度1＋ガード列によるものであり、同一PATCH化単独では閉じない——7.4の通知フロー共通規約参照）。明細側のStatus・AssignedIp・AssignedFqdn・ProcessedAt等の終端書込も明細単位で同一PATCHにまとめる。例外：親作成後の明細部分失敗（UI側防壁）によるFailed確定時は、Power AppsがStatus=FailedとErrorMessageを同時に書き込む（v1.3の二重防壁規定に整合）。親のProcessedAt・ErrorMessage・CompletionNotifiedAtはPower Appsが親作成時にnull（未設定）で初期化する。（v1.4追加） 

Power Automateが親IPRequests.Statusの変更をトリガに完了通知を申請者へ送信。通知内容にはIP、サブネットマスク、ゲートウェイ、DNSサーバを含める（ホスト名ありの時はFQDNも含む）。 

完了通知（付録F#2）・失敗通知（付録F#3）の送信済み判定・更新（CompletionNotifiedAt/FailureNotifiedAt）は付録F#2/#3の記載に従う（7.4の通知フロー共通規約に準拠）。完了通知に記載するセグメント情報（Gateway/SubnetMask/DnsServers）は、Power Automateが親IPRequests.SegmentIdでSegmentsをLookupして取得する（Worker転記方式は採らない。Power AutomateのSegments読取権限は9.1の記載による）。通知フローの最終失敗による欠落は、監視スクリプト（10.4）が「CompletionNotifiedAt未設定かつ親Status終端」を日次検知し、手動再送で回復する（自動再送は行わない）。（v1.4追加） 

（1） 空きIP選定と登録の間に事前再検証は設けず、Add-IpamAddressの一意性エラーをもって重複検知とする（登録操作自体を検証点とし、check-then-actの競合窓を排除）。エラー時は次候補IPで同サイクル内に再選定する（最大3候補）。 

（2） 明細処理の先頭で、IPAMを明細単位キーで検索し、既登録エントリが存在する場合は新規払い出しを行わず、当該IPを用いてDNS登録・SharePoint書込から処理を再開する。DNS重複チェックでヒットしたAレコードのIPが自明細の既登録IPと一致する場合は自己残骸として処理を継続し、不一致の場合のみ重複Failedとする。（v1.2追加。結合テスト観点表でAdd-IpamAddressの重複登録エラーを実機確認すること） 

（3） 3候補すべて重複エラーだった場合、明細のRetryCountを加算しStatus=Pendingへ戻す（次サイクル再試行。上限3回超過でFailed確定の既存経路に合流）。候補選定順序はStaticIpRangeRawの記載順・レンジ内昇順とする（v1.3確定）。 

（4） 即時Failed確定とするエラーは空きIPなし・DNS重複・命名規則違反（恒久エラー）。リトライ対象はGraph・IPAM・DNSの通信/障害系（一時エラー）とする（v1.3確定）。 

※ ErrorCategoryの設定契機（一覧）：NoFreeIp＝空きIP候補3件枯渇によるFailed確定時／DnsDuplicate＝DNS重複（静的レコード）検知時／DnsDuplicateDynamic＝DNS重複（動的登録レコード）検知時／NamingRule＝ホスト名再検証違反時／SystemError＝上記以外の障害系でRetryCount上限到達によるFailed確定時（滞留回収経由を含む）。各値はWorkerが明細Failed確定時に設定し（UI側防壁によるFailedはPower Appsが設定）、付録F#3の文面選択（8.5）に使用する。（v1.4新設） 

（5） 親作成後の明細作成が部分失敗した場合、Power Apps側は明細Patch失敗時にエラー表示し親レコードをStatus=Failedとする（再申請案内）。Worker側はBatchSizeと明細実数の不一致を検知した場合、当該申請を処理保留しnkis-networkへ通知する（v1.3確定）。 

（6） 同一申請内の明細間ホスト名重複は、Power Apps送信時（確認画面遷移前）のバリデーションで排除する（v1.3確定）。 

（7） DNS重複チェックはResolve-DnsNameのAクエリで応答（CNAME解決含む）があれば重複扱い（Failed）とする。既存レコードがエージングタイムスタンプあり（動的登録）と判定された場合はErrorCategory=DnsDuplicateDynamicとし、専用文面で案内する（既存端末の固定化・入替はITポータルへ誘導）。動的レコードの自動削除・上書きは行わない（v1.3確定）。 

7.2 セグメントマスター同期フロー（30分ごと） 

同期Workerは代表サーバ2台（nkdc1、nkdc4）のみを照会し、Get-DhcpServerv4Scope、Get-DhcpServerv4ExclusionRangeを取得する。パートナーサーバ（nkdc2/nkdc5）上の同一ScopeIdは処理対象としない（v1.2変更。フェールオーバー構成の詳細は2.2参照）。 

代表サーバへの照会が失敗した場合、当該サーバ配下スコープの同期のみをスキップし（SegmentsリストとIPAMレンジは前回同期値を保持＝2.2）、他サーバ配下の同期・IPAM由来項目の更新・突合チェック・カバレッジ突合は継続する（サーバ単位の障害分離）。照会失敗の通知は同一サーバにつき1日1回に抑制する（通知抑制の状態はWorkerローカル保持を許容する。8.4参照）。（v1.4追加） 

固定IP範囲を「セグメントCIDRのホスト範囲 −（スコープ範囲 − 除外範囲）− 予約IP（ネットワーク/ブロードキャスト/Gateway）」として算出する。スコープ範囲−除外範囲はDHCPが動的配布する動的プールであり、固定IP範囲はその補集合である（スコープをサブネット全体に定義し除外範囲で固定用領域を確保する運用、スコープを動的プール部分のみに定義する運用の双方に対応）。 

算出した固定IP範囲をWindows IPAMのIPレンジへ同期する（未作成セグメントはAdd-IpamRangeで新規作成、除外範囲変更時はSet-IpamRangeで更新。v1.1追加）。Find-IpamFreeAddressはこのレンジを母集合として空きIPを検索する。 

Get-IpamAddress で固定IP範囲内の使用IP数（UsageCount）を集計（DHCP取得→除外範囲計算→IPAM照会の順で実行）。 

各セグメントの空きIP数（CapacityTotal − UsageCount）が20件以下かチェック（IsActive=trueの全セグメントのみ対象。DhcpScopeExists問わず。v1.2修正：3.1の「全セグメント」を読み替え修正）。20件以下かつAlertLastNotifiedAtが24時間以上前の場合、nkis-network@nkc.co.jpへアラートメール送信・AlertLastNotifiedAt更新。空きIP数が21件以上に回復した場合はAlertLastNotifiedAtをクリア。 

SegmentsリストのうちDhcpScopeExists=trueのレコードに対して差分更新（StaticIpRangeStart/End/Raw、Gateway、SubnetMask、UsageCount、CapacityTotal、DnsServers、LastSyncedAt）。DhcpScopeExists=falseのレコードは手動値を維持する。 

差分更新の対象項目にDnsServersを含める。DhcpScopeExists=trueのセグメントは、代表DHCPサーバからGet-DhcpServerv4OptionValue（オプション006＝DNSサーバ）を取得しDnsServersへ書き込む（8.3参照）。DhcpScopeExists=falseは手動値を維持する。（v1.4追加） 

DHCPスコープ⇔Segmentsリストの突合チェックを実施し、漏れ検知時はnkis-networkへ通知する。 

突合はScopeIdのサブネットとSegments.CIDRをキーとして行う（3パターン検知〔v1.3確定〕の照合キー）。DhcpScopeNameは、同期WorkerがGet-DhcpServerv4Scopeで取得したスコープ名をDhcpScopeExists=trueレコードへ書き込む表示・記録用の項目であり（読み手はUI・通知・運用者）、突合のキーとしては使用しない（スコープ名は人手命名で可変のため）。（v1.4追加） 

ARPカバレッジ突合チェックを実施する（IsActive=trueの全SegmentsのCIDRがいずれかのArpDeviceStatus.TargetSegmentsに含まれること）。漏れ検知時はnkis-networkへ通知する（同一内容は1日1回まで。v1.1追加）。 

あわせて、各IsActive=trueセグメントの突合結果をSegments.CoverageStatus（Covered/Uncovered）へ書き込み、CoverageCheckedAtを更新する。通知の1日1回抑制はCoverageNotifiedAtで管理し、Coveredへの回復時にクリアする。カバレッジ由来項目（CoverageStatus/CoverageCheckedAt/CoverageNotifiedAt）はIsActive=trueの全セグメントを対象にWorkerが更新する（「手動値維持」の対象外。UsageCount等のIPAM由来項目のv1.3規定と同型）。これらの列は通知抑制・運用可視化・監査用であり、自動削除Worker（7.4）の除外判定はこれを参照しない（7.4は実行時再計算）。（v1.4追加） 

削除済みスコープは対応レコードのIsActive=falseに設定（レコード自体は履歴として残す）。 

除外範囲変更で固定IP範囲が縮小・消滅した場合、IPAMレンジは削除せずSet-IpamRangeで縮小反映する。範囲外となった払い出し済みIPは自動削除せず、nkis-networkへ通知して手動判断とする（v1.3確定）。 

範囲外となった払い出し済みIPの削除保護は、7.4のIP単位述語（いずれのIPAMレンジにも属さないエントリは削除判定対象外。Cooldownエントリを除く）による（セグメント単位フラグの解除後も保護が継続する恒常規定）。（v1.4追加） 

固定IP範囲が拡張した場合、RangeChangePendingのfalseへの戻しは「当該セグメントを担当する全ArpDeviceStatus機器のLastSuccessAtが、当該セグメントのLastSyncedAt（レンジ更新時刻）より新しいこと」を条件とする（拡張分レンジのARP台帳化が一巡したことの近似。担当機器がFailed中はfalse化されないが、これはFailed機器由来の削除スキップ保護と整合する安全側の挙動）。（v1.4追加） 

セーフティネット：同期WorkerがSet-IpamRangeによる範囲変更を実行する際、当該セグメントのRangeChangePendingが未設定（false）の場合は自動でtrueを設定し、nkis-networkへ手順逸脱通知を送信する（人手先行フラグが本筋であり、検知前の最大30分窓は残存する——10.3に明記）。（v1.4追加） 

UsageCount・CapacityTotal（IPAM由来項目）はDhcpScopeExists問わず全セグメント対象でWorkerが更新する。「手動値維持」の対象はDHCP由来項目（範囲・Gateway等）に限定する（v1.3確定。付録D-18の全セグメント対象化の趣旨に整合）。 

DhcpScopeExists=falseセグメントの固定IP範囲はCIDR全体（ネットワーク/ブロードキャスト/Gatewayの予約IPを除く）とし、CapacityTotalはWorkerがCIDRから算出する（7.3前文・3.1の一貫規定に整合）。（v1.4追加） 

【同期処理の実行規約】同期処理はセグメント単位で「範囲変更の検知→（未設定なら）RangeChangePending=true設定→Set-IpamRangeによるレンジ更新→Segments差分更新（StaticIpRangeRaw含む）」の順で連続実行する（フラグ設定はレンジ更新より先とする）。全セグメント一括のフェーズ順実行（全セグメントのレンジ更新後にまとめて差分更新する方式）は採らない。実行が中断し「IPAMレンジ＝新／StaticIpRangeRaw＝旧」等の中間断面が残った場合も、次回実行（30分後）の差分更新方式による全量再計算で自己修復する（冪等）。（v1.4新設） 

同期Workerは毎実行、RangeChangePending=trueのセグメントについて解除条件を評価し、成立したセグメントのRangeChangePendingをfalseへ戻す。解除条件は、拡張＝7.2の解除述語（当該セグメントを担当する全ArpDeviceStatus機器のLastSuccessAtがLastSyncedAtより新しいこと）成立、縮小・入替＝当該範囲変更のSegments反映（StaticIpRangeRaw差分更新）完了、とする。人手確認による解除（10.3）も可とする。true→falseの書き手は本ステップ（および人手）であり、これにより払い出し抑制（7.1）・登録保留（7.3）・滞留通知（7.2）の解除経路が確定する。（v1.4新設） 

RangeChangePending=trueが24時間（実測調整前提のパラメータ）を超えて継続する場合、同期Workerがnkis-networkへ滞留通知を送信する（1日1回抑制）。24時間継続の判定に用いる「true化時刻」はWorkerローカルの検知記録による（保持の許容は8.4）。（v1.4新設・v1.4追記） 

※ UsageCount更新には最大30分のタイムラグが発生する場合がある（許容事項）。 

7.3 ARP収集・自動登録フロー（1時間ごと） 

ARP収集Workerの固定IP範囲判定は、サイクル先頭で取得したSegmentsリストに基づいて行う。DhcpScopeExists=trueのセグメントはStaticIpRangeRaw（正本）、falseのセグメントはCIDR全体を判定に用い、DHCPサーバへの直接照会は行わない。データ鮮度は最大30分（セグメント同期Worker周期）の遅延を許容する。払い出しWorker（IPAMレンジ）と同一の同期元を参照するため、範囲変更の反映が完了した定常状態では、Worker間で範囲判定が食い違うことはない。ただし範囲変更の反映途中（DHCP変更は即時、IPAM/Segments反映は最大30分、拡張時のARP台帳化はさらに最大数時間）は食い違い得るため、範囲変更中セグメント（RangeChangePending=true）には払い出し抑制（7.1/7.2）および新規登録の保留（本フロー）を適用する。サイクル先頭のSegmentsスナップショットの取得項目にはRangeChangePendingを含める。（v1.4差替え） 

ARP収集WorkerがPythonスクリプトでArpDeviceStatusリストから対象機器を取得し、順次スキャン。Worker多重起動防止のため、ミューテックスまたはロックファイル方式を実装すること。 

Cisco Catalyst/FortiGate/Yamaha RTX-NVRはSNMP（pysnmp）でipNetToPhysicalTable取得。未対応機器はipNetToMediaTableへフォールバックする。Meraki MXはDashboard API（meraki SDK）で /networks/{networkId}/clients エンドポイントから取得。SNMP収集パラメータ初期値：機器1台あたりタイムアウト5秒・リトライ2回・並列度1（逐次）。パイロット実測（受入基準の1サイクル実測）を踏まえ並列度のみ調整可とする（v1.3確定）。 

収集方式の分岐はArpDeviceStatus.DeviceType（CiscoIOS/FortiGate/YamahaRTX/MerakiMX）で駆動する。Meraki機器はArpDeviceStatus.MerakiNetworkIdを参照して /networks/{MerakiNetworkId}/clients を呼び出す。DeviceTypeが未設定または定義外の値の機器は収集をスキップし、LastErrorMessageに記録のうえConsecutiveFailureCountの加算対象とする（72時間連続でFailed遷移→削除スキップ保護の既存経路に乗せる。サイレントエラー禁止〔8.4〕に整合する安全側の既定挙動）。（v1.4追加） 

収集結果をIP単位で集約（IP→MAC→最終応答時刻）。 

収集結果のうち動的プール（スコープ範囲−除外範囲）内のIPは、IPAM登録・LastSeenAt更新の対象外とする（DHCPクライアントは台帳化しない。対象は固定IP範囲内、DhcpScopeExists=falseのセグメントはCIDR全体。v1.1確定）。 

IPAMへの登録・更新はPythonから直接行わず、収集・突合結果をJSONで出力し、同一タスク内で連続実行するPowerShell反映スクリプトが実施する（IPAMはPowerShellモジュール経由でのみ操作可能なため。v1.1確定）。 

機器処理ごとに結果判定し、ArpDeviceStatusリストをUpsert更新（LastSuccessAt、LastAttemptAt、ConsecutiveFailureCount、CurrentStatus、LastErrorMessage）。 

成功時：CurrentStatus=OK・ConsecutiveFailureCount=0にリセット。Failed→OK遷移時も通知なし。 

失敗時：ConsecutiveFailureCountをインクリメント。 

ConsecutiveFailureCount=72（72時間連続失敗）到達時：CurrentStatus=Failed・nkis-networkへ通知1通・LastNotifiedAt更新。 

ConsecutiveFailureCount>72かつ現在時刻−LastNotifiedAt≧24時間：リマインダ通知・LastNotifiedAt更新。 

  各IPについてIPAMを照会し、登録状態で分岐する。判定条件は「IPAM登録状態」および「動的プール外であること」のみとし、(a)(b)ではIsActiveを条件に含めない。（v1.4差替え） 

(a) 登録済みかつSourceにCooldown値を含む場合（Cooldown復帰分岐）：7.4の復帰正典（※削除後クールダウン注記）に従い、次の順序で復帰処理を実施する——(1) LastSeenAtを検知時刻で更新（最初に実施）、(2) SourceからCooldown値を除去し、元のSource値によらずSource=AutoDetectedとする（DNSレコード・申請台帳は復元しない）、(3) CooldownStartedAtをクリア、(4) RequestIdをクリア。MacAddressは復帰処理では操作しない（以後の更新は(b)以降の既存MAC規則に委ねる）。除去したSourceの元値にRequestedが含まれていた場合はnkis-networkへ復帰通知（付録F#14）を送信する。本分岐はIsActive値・除外セグメント該当有無によらず実施する（既存登録IPの保全であり、3.1のLastSeenAt更新継続と同群）。 

(b) 登録済みかつCooldown値を含まない場合：従来どおりLastSeenAtを更新のみ（前回値から24時間以上経過している場合のみ書き込み。IsActiveは条件に含めない。v1.2規定を維持）。 

(c) 未登録の場合：自動登録（Add-IpamAddress、Source=AutoDetected、MacAddress=検出値、LastSeenAt=検出時刻）。ただし当該IPが属するセグメントのIsActive=falseの場合、またはRangeChangePending=trueの場合は、新規登録を行わない（前者は3.1の対象外規定に整合〔登録＝除外／更新＝非依存の非対称は意図的な設計〕、後者は下記保留規定による）。 

※ 保留の対象は新規AutoDetected登録のみであり、既存エントリのLastSeenAt更新（(a)(b)）は範囲変更中も継続する（既存IPの保全を保留に巻き込まない）。保留された検出IPは次サイクル（範囲反映後）で評価する。遅延は最大1サイクル強であり許容範囲とする。（v1.4新設） 

【v1.4：本箇条は手順44の分岐(c)へ吸収したため、段落そのものを削除する。#14では取り消し線の除去ではなく段落削除〔<w:numPr>ごと削除〕を行うこと】 

申請済みIPでMACが未設定のものにMAC検出値を紐付け（初回のみ）。同一IPで異なるMACを検出した場合は最新タイムスタンプ優先でMAC上書きとする。Source=Requestedの場合はIP競合疑いとしてnkis-networkへ通知し、AutoDetectedの場合は通知なし（v1.1変更）。 

ARP収集実行履歴はWindowsイベントログの専用カスタムログ「IPAM-Worker」に記録する。イベントID：1001=成功／1002=部分失敗／1003=全失敗。 

7.4 自動削除フロー（日次） 

自動削除Workerが日次（JST深夜）でIPAMを走査し、LastSeenAtの経過日数に応じて処理を実行する（日数ベース：30/90/180/365日）。 

経過日数は6.8の日数計算規約に従い、当該セグメントのSkippedDays（6.3）を減じて算出する。この補正はAutoDetectedの30日削除判定・Requestedの段階判定（90/180/365日）・Cooldown満了判定のすべてに共通して適用する（凍結期間は猶予を消費しない。要件変更＝A-1。付録B「既知の制約」項目1・A-1要件文と整合）。以下の削除表・目標段階算出・満了サブフローの各日数判定は、いずれも本補正後の経過日数で評価する。本補正は経過日数側で一度だけ適用し、各判定式に別途「＋SkippedDays」項を重ねて減算・加算しない（6.8-2の日数計算規約を正典とする）。（v1.4追記） 

【IPAMエントリから申請明細の特定】自動削除WorkerがNotificationStage・明細Statusの更新、およびDNS削除対象の特定を行う際の明細特定は、IPAMカスタムフィールドRequestId（「REQ-yyyymmdd-{親アイテムID}-{明細アイテムID}」形式。6.8）から明細アイテムIDを抽出し、IPRequestItemsを直接参照して行う。DNS削除対象のホスト名は当該明細のAssignedFqdnを用いる。RequestIdが空のエントリ（AutoDetected・Cooldown復帰後）は明細結合なしとして段階管理・DNS削除の対象外とする。Source=RequestedにもかかわらずRequestIdが空または形式不正のエントリを検知した場合は、整合性異常としてnkis-networkへ通知し、当該エントリの遷移処理をスキップする。（v1.4新設） 

自動削除WorkerのNotificationStage書込みは遷移時のみとする。目標段階の算出・遷移書込は、SourceにCooldown値を含むエントリを対象外とする（Cooldownエントリは満了サブフローでのみ評価する）。Workerは経過日数から目標段階を算出し（90日未満=None／90〜179日=3M-Reminder／180〜364日=6M-Reminder／365日以上=12M-Deleted）、現在値と異なる場合のみ書き込む。経過日数は6.8-2の補正後の値を用いる（本前文の補正を重ねて適用しない。）。 

書込み時のNotificationSentAtの扱い：当該明細のNotificationSentAtが未設定の場合は同一更新内でクリア（未設定維持）とする。現在値がErrorからの復帰上書きの場合に限り、送信済み（SentAt設定済み）明細のSentAtを保持する（Error復帰ループによる再送防止。通常の段階進行〔3M→6M等〕では遷移時クリアにより次段階の送信が行われる）。現在値がErrorの場合も同規則で目標段階により上書きする（Error状態からの自動復帰経路）。 

ARP応答の復活により経過日数が閾値未満へ戻った場合は目標段階=Noneとなり、同規則により後退遷移とSentAtクリアを行う。ただし明細Status=Archivedの明細は後退遷移（目標段階=Noneの書込）の対象外とする（削除実行済み明細の通知履歴を保全する）。 

再駆動（冪等タッチ）：目標段階と現在値が一致し、かつNotificationSentAtが未設定で、かつ当該段階への遷移書込から1日以上経過している明細（Noneを除く。12M-Deletedを含む）に対しては、同一値の再書込を行いPower Automateトリガを再発火させる（通知フロー側の障害で送信・記帳が宙吊りになった明細のWorker側自動再駆動。送信済み判定はSentAtで行われるため二重送信は生じない）。 

既知の制約：Errorが日数境界（90/180/365日）を跨いで滞留した場合、復帰時の段階通知が最大1段階欠落し得る（単一SentAtフィールドの構造上の制約。次段階遷移ではクリアが走るため最終の12M削除通知は保証される）。（v1.4差替え） 

【先頭処理：ArpDeviceStatus参照】 

自動削除Workerは、走査開始時点のSegmentsリストとArpDeviceStatusリストの現在値から、除外セグメントリストを実行時に再計算して生成する。除外セグメント＝(i) CurrentStatus=Failed機器のTargetSegments展開、(ii) 未カバーセグメント（SegmentsのCIDRがいずれのArpDeviceStatus.TargetSegmentsにも含まれない）の和集合とする。本判定はIsActive値によらず全セグメントを対象とする（3.1の書き分け参照）。Segments.CoverageStatusは参照しない（同列は通知抑制・監査用。6.3参照）。（v1.4差替え） 

除外セグメントリストに含まれる各セグメントについて、Segments.SkippedDaysに1を加算し、LastSkipDateに実行日を記録する（削除評価の凍結日数の累積。6.3参照）。（v1.4追加） 

除外セグメントリストが空でない場合、または当日にレンジ非所属により削除判定を保留したエントリ（7.4-3のIP単位述語による削除保留）が1件以上存在する場合、nkis-networkへ削除スキップ通知（付録F#15）を送信する。通知にはスキップ事由（Failed機器由来／未カバー由来／レンジ非所属由来）を区別して記載し、Failed機器由来は原因機器・連続失敗時間、未カバー由来は担当TargetSegments欠落の旨、レンジ非所属由来は7.4-3のIP単位述語により削除保留となった対象IPを記載し、および事由を問わずスキップ継続日数（Failed機器由来・未カバー由来はSkippedDays値。レンジ非所属由来はIP単位事由のためセグメント単位のSkippedDaysは付さない）を記載する。除外セグメントが0件でレンジ非所属由来の保留IPのみが存在する日も、本条件により#15が発火する。（v1.4差替え・v1.4追記） 

除外集合は走査開始時点のスナップショットであり、走査中の機器状態変化（Failed遷移等）は翌日の実行から反映される。本フロー内のSegments参照（除外セグメント判定に加え、7.4-3のレンジ所属判定・満了サブフローのSkippedDays参照・セグメント特定を含む）は、いずれも同一の走査開始スナップショットを用いる（走査中に同期WorkerがSet-IpamRangeで範囲変更しても判定基準が揺れない。走査中変更の反映は翌日実行から。付録B「既知の制約」項目6と同型）。（v1.4差替え） 

走査対象のIPAMエントリのうち、当該IPがいずれのIPAMレンジ（Segments.StaticIpRangeRaw。DhcpScopeExists=falseのセグメントはCIDR全体）にも属さないエントリは、削除判定・段階遷移の対象外とする（範囲外化IP＝手動判断キュー。7.2の範囲縮小時規定を参照）。当日に本述語で削除判定を保留したエントリは、上記削除スキップ通知（#15）の発火・記載（レンジ非所属由来）の対象とする。ただしSourceにCooldown値を含むエントリはこの保留の対象外とし、レンジ非所属であってもCooldown満了時に物理削除する（範囲返却領域のCooldown残骸を台帳から回収する。復帰猶予は範囲外化時点で観測経路が閉ざされるため、保持しても復元されない）。（v1.4新設） 

Source 

未応答期間 

アクション 

通知 

AutoDetected 

1ヶ月 

削除（IPAMからCooldownへ移行。30日保持後に物理削除） 

なし（不正IP扱い） 

Requested 

3ヶ月 

削除なし 

明細NotificationStage=3M-Reminder更新→Power Automateが集約通知（申請者） 

Requested 

6ヶ月 

削除なし 

明細NotificationStage=6M-Reminder更新→Power Automateが集約通知（申請者+Manager） 

Requested 

12ヶ月 

アーカイブ削除（IPAM+DNS）、明細Status=Archived（全明細Archivedで親もArchived） 

明細NotificationStage=12M-Deleted更新→Power Automateが集約通知（申請者+Manager） 

※（削除表12ヶ月行の補足）明細Status=Archivedへの更新および全明細Archived時の親IPRequests.Status=Archived集約は、自動削除Workerが削除実行と同一処理内で実施する（集約規則は7.1の親Status集約に準拠）。（v1.4追加） 

※ 削除判定ループ内で除外セグメント配下のIPはスキップする（LastSeenAt経過日数を評価しない）。除外セグメント配下のIPは、LastSeenAt基準の削除判定・段階遷移に加え、CooldownStartedAt基準の満了物理削除もスキップする（観測断中のCooldown満了IPを空きプールへ放出しない。凍結日数はSkippedDaysで補正される）。（v1.4追加） 

【スキップ解除時の緩衝】セグメント単位のスキップ事由（Failed機器由来／未カバー由来）が解消した後の最初の自動削除実行——すなわちLastSkipDateが前日（前日にスキップが適用され、当日は当該セグメントがスキップ対象でない）であるセグメント。周期超過でサイクルが欠落した場合の取りこぼしを拾うため、判定は「LastSkipDateが前回実行日以降かつ当日スキップ非適用」とする（前回実行日は8.4の実行履歴〔Windowsイベントログ「IPAM-Worker」の前回実行記録〕から読み取り専用で取得する。削除・除外判定に影響する状態のローカル保持には当たらない。前回実行日が実行履歴から取得できない場合〔イベントログのローテーション等〕は、当該実行では緩衝を適用せず通常の段階判定を行う〔緩衝は次回以降の実行で機能する〕。経過日数のSkippedDays補正は本フォールバックの影響を受けず、常に適用される。（v1.4追加））——では、次の緩衝規則を適用する：(a) 段階遷移（NotificationStage）は1回の実行で1段階までとする。(b) 12ヶ月アーカイブ削除は、当該の「解除後最初の実行」では実施せず翌実行へ持ち越す（解除後にARP収集1サイクル〔1時間。実測調整前提〕以上のLastSeenAt更新機会を挟むための持ち越しであり、解除時刻の記録を要しない操作形とする。意味は等価）。Cooldown満了物理削除は満了サブフローの確認1日（＋31日方式）が同等の緩衝として機能する。（v1.4差替え） 

※ 緩衝の適用対象はセグメント単位のスキップ事由（Failed機器由来・未カバー由来）に限る。レンジ非所属由来のスキップ（7.4のIP単位述語による削除保留）には緩衝を適用しない。理由：レンジ非所属は範囲変更（運用者の意図的操作）に伴うIP単位事由であり、緩衝の判定材料（前日スキップ記録＝LastSkipDate）がセグメント単位記録にしか載らず、また緩衝なしでも実害が小さい（範囲復元後の一括評価で誤リマインダが最大1通生じ得る程度＝安全側の既定挙動として許容）。レンジ非所属状態の終了時刻・解除検知材料は本文で保持せず、緩衝対象外とすることで割り切る。（v1.4差替え） 

※ SkippedDays補正（経過日数の凍結補正）が第一層の保護であり、本緩衝は補正が及ばない事由（レンジ非所属由来＝IP単位のためセグメント単位補正を適用しない）および境界ケースに対する第二層である。（v1.4新設） 

※ DNSレコード削除はSource=Requestedかつホスト名が登録されていたIPのみ対象。 

※ 削除後クールダウン：IPAMにSource=Cooldown値で30日間保持する。30日経過後に物理削除（空きIPプールへ復帰）。Cooldown移行時はSourceにCooldown値を追加付与する（元値は保持）。Cooldown移行時はIPAMカスタムフィールドCooldownStartedAtに削除実行時刻を記録する（起算点。6.8参照）。復帰処理（ARP収集WorkerのIPAM反映スクリプトが検知と同時に実施。IT部門の手動復帰も同一手順に従う）は、当該IPAMエントリに対し次の順序で実施する：(1) LastSeenAtを検知時刻で更新する（最初に実施。以降の操作が部分失敗しても、満了サブフローの条件(3)により削除が抑止される）、(2) SourceからCooldown値を除去し、元のSource値によらずSource=AutoDetectedとする（DNSレコード・申請台帳は復元しない）、(3) CooldownStartedAtをクリアする、(4) RequestIdをクリアする。MacAddressは復帰処理では操作しない（保持。以後の更新は7.3の既存規則〔最新タイムスタンプ優先〕に委ねる）。Requested由来（除去したSource元値にRequestedを含む場合）の復帰時はnkis-networkへ通知する（付録F#14）。クリア・保持対象フィールドの網羅は本注記を正典とし、7.3の復帰分岐・10.7の手動対応はこれに従う。（v1.4差替え） 

【Cooldown満了物理削除サブフロー】 

実行主体は自動削除Worker（日次）とする。削除表の経過日数マッチ・目標段階算出から除外したCooldownエントリ（SourceにCooldown値を含むエントリ）は、本サブフローでのみ評価する。 

満了判定述語：実行日 ≥ CooldownStartedAt＋30日＋1日（6.8-2の補正後経過日数で評価する。「＋1日」は削除確定前の確認日。当該セグメントのSkippedDays補正は6.8-2の経過日数側で既に適用済みであり、本述語に別途「＋SkippedDays」項を加えない。）。当該IPがいずれのIPAMレンジにも属さず「当該セグメント」が特定できないレンジ非所属エントリ（7.4-3の例外で満了物理削除の対象となる範囲返却領域のCooldown残骸）は、SkippedDays=0として評価する（観測経路が閉ざされ復元されない前提のため補正0で害はない）。（v1.4追記） 

削除実行時の追加条件：述語成立に加え、(2) SourceにCooldown値をなお含むこと、(3) LastSeenAt ≤ CooldownStartedAt であること、の2条件を満たす場合に限りRemove-IpamAddressで物理削除し、空きIPプールへ復帰させる。いずれかを満たさない場合は削除せずスキップする（復帰処理の進行中・完了とみなし、以後の扱いは復帰正典に従う）。 

CooldownStartedAtが空値の場合：LastSeenAt＋30日＋1日を代用起算（SkippedDays補正は6.8-2の経過日数側で適用済み。）として判定し、nkis-networkへ整備通知を送信する（代用起算ではLastSeenAt更新により削除が自動的に先送りされるため、条件(3)と等価の保護が成立する。条件(2)は同様に適用する）。 

本サブフローは除外セグメントリストの適用対象とする（除外セグメント配下のCooldownエントリは満了していてもスキップし、付録F#15に含める）。レンジ非所属エントリの削除保留は本サブフローには適用しない（先頭処理のCooldown例外のとおり）。 

DNSレコードはCooldown移行時に削除済みのため、本サブフローでは操作しない。（v1.4新設） 

※ 通知送信時、Power AutomateがOffice 365 Usersコネクタでmanager属性を都度取得する（通知時点の現Managerに送信。WorkerのGraph権限にディレクトリ読み取りは不要）。申請者UPNが見つからない・Manager属性が取得できない等の異常系発生時は、nkis-network@nkc.co.jpに異常通知を送信しログ記録する。NotificationStage=Errorの書込およびnkis-networkへの異常通知送信は、当該通知送信フロー自身がエラー捕捉時に一括で実施する（付録F#7を独立トリガフローとしない。v1.3確定）。Error書込の対象範囲はフロー内の失敗位置で決定する：(a) 宛先解決（UPN/Manager取得）・メール送信呼び出しまでの失敗は集約単位の共通失敗として、集約対象の全明細にErrorを書き込む（この時点で送信済み明細は存在しないため、翌日の再駆動で全件が再集約される）。(b) 送信成功後のNotificationSentAt更新処理中の失敗は明細個別の失敗として、トリガ明細のみにErrorを書き込む（未更新明細は集約フローの再クエリおよびWorkerの冪等タッチで回収される）。いずれの場合も、Error書込はフローのエラー捕捉における最初の操作として実施する（再駆動の種を優先確保）。NotificationSentAt設定済み明細のSentAtはError書込時もクリアしない。 

本規定はNotificationStage連動の集約送信フロー（付録F#4〜#6の共通経路）に適用する。完了通知#2・失敗通知#3はManager取得を行わず宛先が申請者のみのため本規定の主対象外とし、異常時は8.4のサイレントエラー禁止（nkis-network到達保証）に従う。（v1.4追加） 

※ 通知の集約送信（v1.1）：Power AutomateはIPRequestItems.NotificationStageの変更をトリガ（フロー並列度1）とし、同一ParentItemId・同一NotificationStage・NotificationSentAt未設定の明細を集約して1通のメールで送信する（本文に対象明細のIP/ホスト名一覧を記載）。送信後に各明細のNotificationSentAtを更新する。SharePointトリガは列単位の変更検知を持たないため、トリガ条件とNotificationSentAtによる送信済み判定で多重発火を防止すること。 

【通知フロー共通規約】（NotificationStage連動集約フロー〔#4〜#6〕、完了通知#2、失敗通知#3に共通）：(1) フロー並列度は1とする。(2) 送信と送信済み記帳の順序は「メール送信成功を確認→ガード列（NotificationSentAt／CompletionNotifiedAt／FailureNotifiedAt）を更新」とする。送信成功後・記帳前の失敗時は次回発火時に未記帳として再送される（冪等許容再送。送信中マーカによる二相方式は採らない——ガード列は日時型でありマーカ値域がないため）。(3) トリガはat-least-once配送であり、多重発火の抑止は並列度1の直列化とガード列の送信済み判定の組で行う（トリガ発火回数の削減策〔親の同一PATCH化等〕単独では二重送信は閉じない）。 

【削除通知（#4〜#6）固有規定】：集約フローはトリガ発火後に「同一ParentItemId・同一NotificationStage・NotificationSentAt未設定」の明細を再クエリして集約母集合を確定し、1通で送信する（Worker逐次書込途中の部分集約の回避）。自動削除Workerは同一ParentItemId・同一目標段階の明細書込を原則同一実行サイクル内で完了させる。書込がサイクルを跨いだ場合も、後続書込のトリガによる再クエリが未送信明細を回収するため欠落・重複なく収束する（持ち越しの自己修復）。 

【既知動作】SharePoint書込障害の継続中は、同一段階の通知が複数回届き得る（許容再送。送信済み記帳が成立した明細は再送されない）。通知文面の確定（13章）では再送があり得る前提の文言を検討する。（v1.4追加） 

※ 本フローの既知の制約（Failed遷移前72時間の非保護窓、走査開始スナップショットの1夜窓、Error境界跨ぎの最大1段階通知欠落等）は付録Bの既知の制約一覧を参照。（v1.4新設） 

8. Worker設計 

8.1 実行環境 

Azure VM（Windows Server 2022以上）上にIPAM本体と全Workerを同居配置する。 

VMサイジング目安：4vCPU / 16GB RAM / OSディスク128GB（Premium SSD）+ データディスク128GB。 

社内ADドメイン参加（Azure VMの社内ドメイン参加は既存運用実績に準拠）。 

IPAMデータベースはデフォルトのWID（Windows Internal Database）で構築（規模上、SQL Server不要）。 

PowerShellスクリプト（IP払い出し・同期・自動削除）およびPythonスクリプト（ARP収集）はデータディスクに配置する。 

タスクスケジューラで定期実行。実行アカウントは専用サービスアカウント。 

Python実行環境（3.11以上）はWorkerサーバへ導入し、ランタイムのパッチ適用はネットワーク/インフラチームの運用とする。 

ログ出力はデータディスク配下とし、Azure Backupの対象に含める。 

8.2 必要権限 

Windows IPAM管理者権限（IPAM Administrators）。 

Windows DHCP（オンプレ4台）への読み取り権限（DHCP Users相当）。 

AD統合DNSの ad.nkc.co.jp ゾーン書き込み権限、および対応する逆引きゾーンの書き込み権限。 

対象NW機器へのSNMP読み取り権限（コミュニティ名またはSNMPv3アカウント）。 

Meraki Dashboard APIキー（Read-Only権限、組織単位）。 

Microsoft Graph API認証はEntra IDアプリ登録+証明書認証（最小権限：SharePointリストアクセスのみ）。 

8.3 使用する主なコマンド・ライブラリ 

PowerShell（Windows IPAM/DHCP/DNS操作） 

Find-IpamFreeAddress：空きIP検索 

Add-IpamAddress、Set-IpamAddress、Remove-IpamAddress、Get-IpamAddress：IPAM操作 

Add-IpamCustomField、Add-IpamCustomValue：カスタムフィールド定義（初回のみ） 

Add-IpamSubnet、Add-IpamRange、Set-IpamRange：IPAMサブネット/レンジの作成・同期（固定IP範囲の母集合管理。v1.1追加） 

Get-DhcpServerv4OptionValue：Gateway/DNSサーバ等のスコープオプション取得（v1.1追加） 

Send-MailMessage または System.Net.Mail.SmtpClient：社内SMTPリレー経由のアラート送信（v1.1追加） 

Get-DhcpServerv4Scope、Get-DhcpServerv4ExclusionRange：DHCPスコープ・除外範囲取得 

Add-DnsServerResourceRecordA（-CreatePtr付き）、Remove-DnsServerResourceRecord：DNSレコード操作 

Resolve-DnsName：DNS重複チェック（書込先と同一のDNSサーバを-Serverで明示指定し、AD複製遅延による重複見逃しを防止） 

Invoke-RestMethod：Graph API経由でSharePointリスト読み書き 

Write-EventLog：Windowsイベントログ「IPAM-Worker」への記録 

New-EventLog / Limit-EventLog：カスタムイベントログ「IPAM-Worker」の初回作成・サイズ設定（イベントログ最大512MB・上書きモード。ファイルログは日次ローテーション・90日保持。v1.3確定） 

Python（ARP収集） 

pysnmp または easysnmp：SNMP walk（Cisco/FortiGate/Yamaha） 

meraki（公式SDK）：Meraki Dashboard API 

netmiko + ntc-templates（TextFSM）：将来的な機器台帳自動化用（初期実装ではSNMP優先） 

ipaddress（標準ライブラリ）：IP集合演算 

msal：Microsoft Graph API認証（ArpDeviceStatus更新に使用） 

smtplib（標準ライブラリ）：社内SMTPリレー経由のアラート送信（v1.1追加） 

8.4 エラーハンドリング方針 

サイレントエラー禁止：全例外は必ずログ記録＋通知経路（申請者 or nkis-network）に到達させる。 

登録・払い出し時のIP重複は100%検知：IPAM登録・払い出し・ARP検出の3経路で登録重複チェック、検知時は即時nkis-networkへ通知。運用中のIP競合疑い（Source=RequestedのIPで登録済みと異なるMACを検出）はMAC上書きと同時にnkis-networkへ通知する。 

RetryCount上限3回：上限到達でStatus=Failed確定＋nkis-networkへエスカレーション通知。 

Worker多重起動防止：ミューテックスまたはロックファイル方式を実装要件に明記。ロックファイル方式を用いる場合は、ロックに保持プロセスID・取得時刻を記録し、起動時に保持プロセスの生存確認またはタイムスタンプの失効判定（Worker想定所要の上限超過で失効）を行って残骸ロックを自動解放する（クラッシュ残骸による恒久起動拒否の防止）。Worker間排他（次項）にロックファイルを用いる場合も同一の自動失効規約に従う。（v1.4差替え） 

Worker間排他（IPAMエントリ更新）：自動削除Worker（日次02:00）とARP収集WorkerのIPAM反映処理が同一IPAMエントリを同時更新しないよう、IPアドレスをキーとしたエントリ単位の名前付きミューテックスで相互排他する。ロック保持は当該エントリの更新操作区間のみとする。待ちタイムアウトは秒オーダー（例：10秒。実測調整前提）とし、超過時は当該エントリをスキップして処理を続行する（ARP反映側は次サイクル、削除側は翌日に再評価。Cooldown満了サブフローの＋1日確認とLastSeenAtガードが安全網となるため、スキップは安全側）。グローバルロック（1本のロックによる全体排他）は、02:00走査中のARP反映全停止→周期超過→サイクル欠落の連鎖を招くため採用しない。v1.4新設 

周期超過時の挙動：各Workerの実行が次回起動時刻を超過している場合、次回サイクルは多重起動防止により起動をスキップする（サイクル欠落を許容し、二重実行はしない）。スキップの発生はイベントログへ記録し、監視スクリプト（10.4・付録F#20経路）が超過・スキップの常態化を検知して通知する。各Workerの走査所要時間は受入時に実測し（11.3のARP 1サイクル実測に自動削除Worker・同期Workerの走査所要を追加する）、周期設計の妥当性を確認する。v1.4新設 

ARP収集セーフティ：機器単位パターンβ採用。72時間連続失敗でFailed遷移通知・Failed機器担当セグメントの自動削除スキップ。 

冪等性を確保。同一RequestIdで複数回実行されても二重払い出しにならないよう、Processingステータスで排他制御。払い出しの重複検知はAdd-IpamAddressの一意性エラーおよび明細単位キーによる既登録チェックで行う（check-then-actの競合窓を排除。詳細は7.1参照。v1.2変更）。同期Workerの中間断面（レンジ更新済み・Segments未更新等）は、次回実行の全量差分更新で自己修復する（7.2）。IP払い出しWorkerは、サイクル先頭の親集約修復により親Status集約の欠落断面を修復する（7.1）。クラッシュ・中断はいずれも次サイクルの再実行で収束することを実装規約とする。（v1.4追加） 

Processing滞留回収：Processingのまま最終更新から30分以上経過した明細はPendingへ戻し、nkis-networkへ警告通知する（v1.1追加）。Pendingへ戻す際はRetryCountを加算し、上限到達時はIPAMロールバック（DNS登録済みの場合はDNSレコード削除を含む）のうえFailed確定する（加算経路を問わず上限3回で終端。詳細は7.1）。（v1.4追加） 

日数閾値の外部パラメータ化：削除判定の日数閾値（30日／90日／180日／365日、Cooldown 30日、スキップ解除時の緩衝等の時間パラメータ）は、Worker内にハードコードせず外部パラメータ（設定ファイル）として保持する。設定値には下限7日のガードを設け、これを下回る値は起動時に拒否する（受入検証時の時間依存動作の検証に用いる閾値短縮のため。v1.3で確定済みの事項を本文へ明文化したもの）。初期稼働期間における運用値の規定は10.2による。v1.4新設 

Workerローカル保持の許容範囲：通知抑制の状態、および滞留検知の初回検知時刻（RangeChangePendingのtrue化時刻。喪失時は24時間カウントが再開し通知が遅延するのみで安全側）に限り、Workerローカル保持を許容する（喪失時は再通知となるのみで安全側。前項のロックファイル自動失効規約と同一の管理下に置く）。削除判定・除外判定に影響する状態のローカル保持は不可とする。なお、スキップ解除時の緩衝トリガ（7.4）が参照する「自動削除Workerの前回実行日」は、Windowsイベントログ「IPAM-Worker」の実行履歴（9.3・10.4）から読み取り専用で取得する。これは実行済み履歴の参照であり、削除判定・除外判定に影響する状態をWorkerローカルに保持することには当たらない（履歴喪失時は緩衝が1回効かないのみで安全側）。代表DHCPサーバへの照会失敗通知（7.2）の1日1回抑制は本規定によりWorkerローカルの抑制記録（サーバ名×JST日付）で管理し、Segments（6.3）への列追加は行わない。v1.4新設v1.4新設 

Graph API一時エラーは指数バックオフでリトライ（最大3回）。初期待機2秒・倍率2（2/4/8秒）。対象は429/408/5xx/接続タイムアウトとし、429はRetry-Afterヘッダを優先する（v1.3確定）。 

DNS登録に失敗した場合、IPAM側のエントリをロールバックして整合性を保つ。逆引きゾーン未設定等のDNS環境不備による失敗も同様にロールバックし、nkis-networkへ環境不備通知を送信する。 

ログはWindowsイベントログとファイルの両方に出力。 

Worker発のアラートメールは社内SMTPリレーサーバ経由で送信する（v1.1確定。送信元アドレス・リレーFQDNは運用手順書で定義。WorkerサーバIPのリレー許可元登録が必要）。 

8.5 Failed時の通知 

申請失敗時の申請者向けメッセージ： 

失敗原因 

申請者へのメッセージ 

ホスト名のDNS重複 

指定のホスト名はすでに登録されています。ホスト名を変更して再申請してください。 

ホスト名のDNS重複（動的登録レコード起因。ErrorCategory=DnsDuplicateDynamic） 

指定のホスト名は既存端末で使用中の可能性があります。既存端末の固定化・入替をご希望の場合はITポータルよりご相談ください。 

空きIPなし 

選択したセグメントに空きIPがありません。ITポータルよりお問い合わせください。 

ホスト名命名規則エラー 

ホスト名が命名規則に合致しません。申請フォームの注記を確認のうえ再申請してください。 

システムエラー（IPAM/DNS/Graph障害。ErrorCategory=SystemError。RetryCount上限到達によるFailed確定を含み、Processing滞留回収経由で上限到達した場合も本区分とする。設定契機の一覧は7.1の集約注記を正とする）（v1.4差替え／「失敗原因」欄のみ改訂） 

システムエラーが発生しました。しばらく時間をおいて再申請してください。改善しない場合はITポータルよりご連絡ください。（申請者へのメッセージ欄は不改訂） 

nkis-networkへの通知： 

IPAMロールバック失敗時：nkis-networkへ緊急アラート送信。 

RetryCount上限到達時：nkis-networkへエスカレーション通知。 

削除スキップ発生時：nkis-networkへ削除スキップ通知（日次、付録F#15）。Failed機器由来・未カバー由来・レンジ非所属由来を問わず、スキップが発生した場合に事由別に記載する。（v1.4差替え） 

DNS環境不備（逆引きゾーン欠落等）検知時：nkis-networkへ環境不備通知（v1.1追加）。 

Processing滞留回収発生時：nkis-networkへ警告通知（v1.1追加）。 

IP競合疑い（Source=Requestedの異MAC検出）：nkis-networkへ競合疑い通知（v1.1追加）。 

Cooldown中のIP復帰（Requested由来）：nkis-networkへ通知（v1.1追加）。 

通知イベントの全一覧は付録F「通知一覧」を参照（v1.1追加）。 

9. セキュリティ・権限設計 

9.1 認証・認可 

Power AppsアクセスはEntra ID認証必須。匿名アクセス不可。 

Power Apps利用権限は、社員全員（または指定グループ）に付与。 

SharePointリストの直接編集権限はネットワーク/インフラチーム3名のみ。一般ユーザはPower Apps経由のみ。 

Power AppsのSharePoint権限：IPRequestsは作成・自分のレコード読み取り、Segments/Regions/OfficeLocationMapは読み取りのみ。IPRequestItemsにはIPRequestsと同一の「作成＋自分のレコード（作成者=本人）の読み取り」を付与する（v1.3確定）。 

オンプレWorker（Azure VM上）のGraph APIアクセスは専用Entra IDアプリ登録+証明書認証、最小権限（SharePointリストアクセスのみ）。監視スクリプト（同一VM上・日次07:00）は、Workerと同一のアプリ登録・最小権限の範囲でIPRequests／IPRequestItemsを読み取りのみ参照する（完了通知欠落および親Status=Pending滞留の検知用。10.4）。監視スクリプトへの書込権限は付与しない。（v1.4差替え） 

Power Automate（申請受付フローのサービスアカウント）に、OfficeLocationMissLogリストへの作成権限を付与する（書込主体は7.1による）。v1.4新設 

Power Automate（完了通知フロー）にSegmentsリストの読取権限を付与する（#2のセグメント情報Lookup用。7.1）。v1.4新設 

AD統合DNS（ad.nkc.co.jpおよび逆引きゾーン）への書込権限のサービスアカウント付与は、セキュリティ部門承認済み（v1.1明記）。 

9.2 サービスアカウント権限 

IPAM操作は専用サービスアカウント（Azure VM上）で実行。 

Power AutomateおよびPower Appsは既存E5ライセンス付与済みのシステムアカウントを流用して所有する（担当チーム確認結果待ちの条件付き確定。NG判明時は再協議。C.4試算は当該アカウントの既存リクエスト消費込みで実施する。v1.3確定）。 

Meraki APIキーはRead-only、キーローテーション手順を運用手順書に定義。 

Graph API用証明書は有効期限を監視し（期限60日前にnkis-networkへ通知）、更新手順を運用手順書に定義する（付録E参照。v1.1追加）。 

9.3 監査 

SharePointのバージョン履歴で全レコードの変更履歴を保持。 

Power Automateの実行履歴でワークフロー処理を追跡。 

WorkerはWindowsイベントログ（専用カスタムログ「IPAM-Worker」含む）に全実行を記録。 

Entra IDサインインログでPower Appsアクセスを追跡。 

Worker/Power Automate起因の変更（システム起因変更）はサービスアカウント名義で記録されるが、RequestId・イベントログ経由で申請者へ間接的に追跡可能である（3.2の全申請・全変更追跡要件の充足解釈。v1.3確定）。 

SharePoint監査ログ保持期間の適合性は付録C（事前調査チェックリスト）で確認する。 

10. 運用設計 

10.1 端末側の手動設定運用 

申請完了通知にIP、サブネットマスク、デフォルトゲートウェイ、DNSサーバを明記。ホスト名を登録した場合はFQDNも含む。 

通知メール本文に「通知された新IPに手動設定変更をお願いします」を明記する（AutoDetected登録済みのIPが払い出された場合の運用ガイド）。 

Windows向けの手動設定ガイドは既存社内ドキュメントを参照（申請完了メール本文にリンクを掲載）。 

Windows以外（Linux/macOS/プリンタ/NW機器/その他）は申請者側で各自設定。必要に応じてITポータルへ問い合わせ。 

DHCPクライアント設定のままにしないよう、静的設定への変更は申請者責任で実施。 

10.2 既存手動設定IPの取り扱い 

既存の手動設定IPはARP収集Workerによって自動的にAutoDetected登録される。 

管理者が用途不明の自動検出IPについて棚卸しを行う運用は設けない（工数の都合）。 

1ヶ月（30日）ARP応答がなければ不正IPとして自動削除される。ただし初期稼働期間（ARP台帳化開始後90日を推奨。実測調整前提）は、既存の手動設定固定IPが一括でAutoDetected登録される（3.2）ことに伴い、削除閾値の同時到達による一斉Cooldown移行・一斉プール放出が生じ得るため、AutoDetected自動削除の日数閾値を初期延長値（90日を推奨。実測調整前提）で運用する。定常値（30日）への切替は、Cooldown移行件数（イベントログで観測）が定常想定（年間十数件ペース）へ収束したことを確認して実施する。閾値は外部パラメータ（8.4）であり、切替に実装変更は不要である。初期整備期間中の削除スキップ通知（付録F#15）は、台帳整備の進捗指標として扱う。この初期延長期間中は、真に不要となったAutoDetected IPの回収も同じ日数閾値ぶん延伸するが、これは台帳化の安定と引き換えの運用上の特性であり（定常値への切替で解消）、付録B「既知の制約」ではなく本項に運用特性として記す。（v1.4差替え。要件変更＝A-3） 

既存機器を申請済み状態へ昇格させる機能は本プロジェクトでは実装しない（将来拡張）。 

10.3 DHCPスコープ変更時の運用 

除外範囲の変更は、同期Workerが次回実行（最大30分後）に反映する。除外範囲変更・CIDR入替（旧レコードのIsActive=false化＋新規作成）を行う際は、対象セグメントのRangeChangePending=trueを先に設定してからDHCP側を変更する（フラグ先行。逆順の場合、同期Workerのセーフティネット検知〔7.2〕までの最大30分間は無保護となる——既知の制約）。縮小・入替は同期反映完了後、拡張はARP台帳化の一巡条件（7.2の解除述語）成立後に、同期Workerの判定または人手確認でfalseへ戻す。緊急変更で同期Workerを手動実行する場合も同一のフラグ運用に従う。フラグの24時間超滞留は自動通知される（7.2）。（v1.4差替え） 

代表サーバ側のスコープ設定変更後、フェールオーバー複製（Invoke-DhcpServerv4FailoverReplication）でパートナーサーバへ反映する。反映漏れが疑われる場合は手動でレプリケーションを再実行する（v1.2追加）。 

代表DHCPサーバ（nkdc1/nkdc4）の障害・照会失敗が継続している間は、当該サーバ配下スコープの除外範囲変更・スコープ変更を原則行わない（変更がIPAM/Segmentsへ反映されず、払い出し判定と実配布が乖離するため）。障害中にやむを得ず変更する場合は、対象セグメントのRangeChangePendingを人手で設定して払い出しを止めてから実施する（この間、人手フラグが唯一の保護となる）。障害復旧時、フェールオーバー構成のパートナーサーバ側で行った変更を代表側へ複製する際は、代表→パートナー方向の旧定義での逆複製（変更の巻き戻し）を行わないこと（ペア間整合の確認は付録C.1(3)の手順に準拠する）。v1.4新設 

緊急変更時は管理者が同期Workerを手動実行。 

新規DHCPスコープ追加時は、ネットワーク/インフラチームがSegmentsリストに手動で該当レコードを追加し、DhcpScopeExists=trueを設定する。 

CIDR変更は禁止。変更が必要な場合は旧レコードのIsActive=falseを設定し、新CIDRで新規レコードを作成する。固定IP範囲の縮小・返却を計画する際は、縮小予定範囲内にSource=RequestedおよびCooldownのIPAMエントリが残存しないことを事前に確認する（残存がある場合は移行・満了を待ってから縮小する）。本チェックは人手のチェックリスト項目であり、技術制御では代替できない（既知の制約）。（v1.4追加） 

10.4 障害・エラー時の運用 

IP払い出しWorker停止時：Pending案件が蓄積。復旧後に自動処理再開。申請者には「処理中」通知のみ。 

ARP収集Worker停止時：LastSeenAt更新が停止。Windowsイベントログ（IPAM-Worker）の前回実行結果を監視スクリプトが日次チェックし、失敗/未実行時はnkis-networkへ通知する。また、自動削除Worker起動時にArpDeviceStatusでFailed機器を確認し、該当セグメントの削除をスキップする。 

監視スクリプトの検知網（日次07:00）：監視スクリプトは次を検知し、nkis-networkへ通知する（いずれも検知・通知のみで、自動修復・自動再送は行わない）。(1) 各Workerの前回実行結果の失敗・未実行（既存）。(2) 実行周期の超過・サイクルスキップの常態化（8.4の周期超過規定）。(3) 完了通知の欠落：CompletionNotifiedAtが未設定であり、かつ親Statusが終端（Assigned/PartiallyFailed）である申請（手動再送依頼として通知する。#2はFailedに発火しないため終端集合からFailedを除く。付録F#2と整合）。(4) 親の滞留：親Status=Pendingのまま作成から24時間を超過した申請（集約欠落・ハング・保留の統一検知）。(3)・(4)の検知後の手動補完手順（通知の再送・親集約の手動実行）は運用手順書に記載する（成果物）。監視スクリプトのSharePoint権限は読み取りのみである（9.1）。v1.4新設 

DNS登録失敗時：IPAM登録もロールバックし、申請をFailedに戻す。申請者は再申請。 

SharePointアクセス障害時：Workerはリトライし、継続失敗時は管理者通知。 

Azure VM自体の停止はAzure Monitorのハートビートアラートで検知し、nkis-networkへ通知する（VM上の監視スクリプトでは自VMの停止を検知できないため。v1.1追加）。 

Failed案件の対応はベストエフォート（SLAなし）。申請者には8.5節のメッセージで次アクションを案内する。 

ユーザからの問い合わせ・申請ミス報告はすべて既存のITポータル経由で受け付ける。本システム専用のTeamsチャネル等は設けない。 

ArpDeviceStatusリストの運用：SharePointビューでCurrentStatus=Failedフィルタを保存し、チームが障害中機器を常時把握できる運用とする。 

10.5 バックアップ構成 

DHCPサーバ（オンプレ4台）：既存のサーババックアップ体制に準拠。本プロジェクトでの追加設計はなし。 

IPAM+Workerサーバ（Azure VM）：Azure Backup MARSエージェントで日次バックアップ。 

バックアップ対象：System State（IPAM WIDデータベース含む）、データディスク全体（Workerスクリプト・設定・ログ） 

リテンション：日次30日 / 週次13週 / 月次12ヶ月 

Recovery Services vaultは本システム専用に作成 

SharePointリスト：M365標準機能で対応。バージョン履歴（各リストで有効化）・ごみ箱（93日）。 

追加のサードパーティバックアップは導入しない 

復旧手順書を外部発注先の成果物として1部納品する。 

リストア後はIPAM・SharePoint・DNSの三者整合性確認と再同期を実施する（IPAMのみ過去断面に戻ると再払い出し重複の恐れがあるため。手順は復旧手順書に含める。v1.1追加）。 

10.6 マスターメンテナンス 

Regions、Segments（DhcpScopeExists=falseのレコード）、OfficeLocationMapの更新はネットワーク/インフラチーム3名がSharePointリスト直接編集で実施。Segmentsの直接編集時はネットワークアドレス誤り・CIDR形式混同に注意すること（人手確認のみ、自動バリデーションなし）。 

新拠点開設・廃止に伴う更新は、ネットワーク構築作業の一環として同時実施する。 

OfficeLocationMapのマップ更新は、MissLogの通知メールをトリガとして都度実施する。MissLog通知はOfficeLocationが非空の未マッチのみを対象とする（空値は記録のみで即時通知対象外。3.1・付録F#8）。（v1.4追加） 

ArpDeviceStatus（収集機器の追加・廃止・TargetSegments変更）もネットワーク/インフラチームの直接編集で維持する。新拠点開設・機器リプレース時はネットワーク構築作業の一環として同時実施する（v1.1追加）。機器行の追加時は、DeviceType・MerakiNetworkId（Meraki機器）・MerakiOrgId（台帳用）の投入を必須とする（DeviceType未設定・定義外値の機器は収集がスキップされる。7.3）。初期一括投入は付録C.6成果物の機器一覧を流用し、責任分界は付録Gによる。（v1.4追加） 

セグメント廃止・収集機器撤去の手順（順序固定）：(1) 廃止前棚卸し——当該セグメントの残存IPAMエントリ（Requested/Cooldown/AutoDetected）を確認し、必要な移行・手動削除（10.7）を完了させる。(2) 残存エントリの整理完了後にSegments.IsActive=falseとする。(3) 収集機器の行削除・TargetSegments変更は、担当セグメントのすべてがIsActive=false化された後に行う（逆順で機器を先に消すと、稼働中セグメントが未カバー化し削除スキップが発生する）。(4) 廃止後に同一CIDR帯で機器が再出現しても新規登録はされない（3.1）。再出現IPの台帳回収はIsActive=true復帰時の次ARPサイクルでの自己回復のみであり、廃止手順(1)(2)の遵守が発生源対策である（既知の制約）。(5) 廃止セグメント配下のIPAMエントリが全て回収され配下が空になったことを確認の上、当該Segmentsレコードおよび対応IPAMレンジを手動削除する（削除により当該セグメントは自動削除スキップ・#15通知の対象から外れる）。空でない段階での削除は行わない（宙に浮くIPの防止）。手順の詳細は運用手順書（成果物）に記載する。（v1.4追記）v1.4新設 

MissLogへのレコード追加時、Power Automateでネットワーク/インフラチームへ即時メール通知する。 

マスターメンテナンスの具体手順は社内運用手順書（外部発注先の成果物）に記載する。 

IPAMカスタムフィールドの復旧手順は運用手順書（外部発注先成果物）に復旧スクリプトとして含める。 

10.7 IT部門による手動対応（v1.2新設） 

IT部門による手動削除（申請ミス・移行等）は、自動削除と同一の状態遷移で処理する。すなわち次の4点を実施する。（v1.4差替え。地の文の連番(1)〜(4)を箇条書きへ組み替えたもので、内容は不変）【(g)-3】 

DNSレコード削除（ホスト名登録ありの場合）。 

IPAMエントリのSource=Cooldown移行（30日保持。手動削除にも一律適用）。移行にあたっては元のSource値を保持したままCooldown値を追加付与する（マルチバリュー。元値を消去・置換しないこと——復帰時のRequested由来判定〔付録F#14〕に使用する）。CooldownStartedAtを同時に設定する（6.8）。（v1.4追加） 

IPRequestItems.Status=Archived設定およびErrorMessage欄への手動対応の旨とITポータル案件番号の記録。 

全明細Archived時の親Status更新。 

手順は運用手順書にチェックリストとして記載する。手動でCooldown中のIPを復帰させる場合は、7.4の復帰正典（※削除後クールダウン注記。クリア・保持対象フィールドの網羅列挙）に従う。（v1.4追加） 

11. 確定事項サマリ 

本章はv1.1レビュー時点の確定事項サマリである。v1.4改訂による発展的変更は各セクション本文（特に7.4・付録B）を正とする。（v1.4追記） 

払い出し対象範囲：全IT機器（サーバ・プリンタ・NW機器・PC・その他）。 

ホスト名：任意入力。未入力時はDNS登録スキップ。 

UIカスケード：地域（都道府県/国）→拠点→セグメントの3段構成。 

承認フロー：なし（申請即自動処理）。 

削除機能：ユーザ向けには実装しない。ITポータル経由の手動対応。 

終了予定日：廃止（全申請を恒久扱い）。 

ホスト名命名規則：^(NKSV|NKNODE|PCD|PCM|PCS|PRT)[0-9]{1,6}$（大文字変換後バリデーション、最大12文字）。SharePoint保存およびDNS登録はいずれも大文字に正規化した値で統一する（v1.3確定）。 

Source of Truth：IPアドレスはWindows IPAM、セグメント定義はSegmentsリスト。 

配置構成：IPAM+Workerを同一Azure VMに同居。オンプレDHCP/DNS/NW機器とはVPN/ExpressRoute経由で連携。 

バックアップ：Azure Backup（MARS）でAzure VMを日次バックアップ、SharePointは標準機能で対応。 

マスターメンテ：ネットワーク/インフラチーム3名がSharePoint直接編集。 

問い合わせ窓口：既存ITポータルに一本化。 

Failed対応：ベストエフォート（SLAなし）。 

削除通知方式：案B採用（Worker→IPRequestItems（明細）のNotificationStage更新→Power Automateトリガ。同一申請・同一段階は集約して1通送信）。 

ARP収集セーフティ：機器単位パターンβ（ArpDeviceStatus管理・72h連続失敗検知・削除スキップ）。 

クールダウン実装：IPAMにSource=Cooldown値で30日保持後に物理削除。期間中の復帰はAutoDetected扱い（Requested由来はnkis-network通知）。 

エラーハンドリング：サイレントエラー禁止・登録/払い出し時のIP重複100%検知・明細単位RetryCount上限3回・Worker多重起動防止。 

固定IP範囲の算出（v1.1確定）：セグメントCIDRのホスト範囲 − 動的プール（スコープ範囲−除外範囲）− 予約IP。 

ARP登録範囲（v1.1確定）：固定IP範囲内のみ（動的プール内の検出IPは登録しない）。 

通知経路（v1.1確定）：ユーザ向け通知はPower Automate、Worker発アラートは社内SMTPリレー経由。 

冗長ゲートウェイ（v1.1確定）：ArpDeviceStatusへは代表1台のみ登録（代表機障害時のARP検知停止を許容）。 

付録A. 用語 

用語 

説明 

IPAM 

IP Address Management。IPアドレスの割当・管理を行う仕組み。本書ではWindows Server標準機能を指す。 

Source of Truth 

「真実の源泉」。ある情報について、最も信頼できる一次情報源となるシステムまたはデータ。 

Requested 

IPAMのSourceフィールド値の一つ。申請経由で登録されたIPを示す。 

AutoDetected 

IPAMのSourceフィールド値の一つ。ARP収集で自動検出・登録されたIPを示す。 

LastSeenAt 

IPAMのカスタムフィールド。最終ARP応答日時。 

クールダウン期間 

削除されたIPを即座に空きプールに戻さず一定期間保持する運用。本書では30日。クールダウン中はIPAMにSource=Cooldown値で保持し、30日経過後に物理削除する（実効：30日保持＋確認1日。物理削除は自動削除Workerが日次で行うため公称30日に対し実効31日。7.4）。期間中にARP応答を検知した場合はSource=AutoDetectedとして復帰する（Requested由来はnkis-networkへ通知）。（v1.4追記） 

SiteCode 

拠点コード。3段カスケードの中間段に使用。 

OfficeLocationMap 

Entra IDのOfficeLocation値をRegionCode/SiteCodeに変換するSharePointマスターリスト。 

MissLog 

OfficeLocationMapに未マッチだったOfficeLocation値の記録用リスト。OfficeLocationMissLog。 

MARSエージェント 

Microsoft Azure Recovery Services エージェント。Azure Backupでオンプレ/VMのファイル・System Stateバックアップに使用。 

ArpDeviceStatus 

ARP収集機器のステータス管理リスト。機器別の連続失敗回数・担当セグメントを保持。 

動的プール 

DHCPが動的配布する範囲（スコープ範囲−除外範囲）。固定IP範囲はその補集合（予約IP除く）。v1.1で定義。 

SkippedDays 

自動削除評価がスキップされた日数の累積（セグメント単位）。削除猶予・Cooldown満了の経過日数計算において、収集経路が有効でなかった期間を猶予から差し引くための補正項。ARP観測が抑止されていた期間は削除猶予を消費しない（6.3・7.4）。v1.4新設 

RangeChangePending 

固定IP範囲の変更（除外範囲変更・CIDR入替）がDHCP側で実施され、IPAMへの反映（および拡張時のARP台帳化）が未完了である状態を示すセグメント単位フラグ。true期間中は当該セグメントの新規払い出し抑制・新規AutoDetected登録保留・滞留検知通知が働く（6.3・7.1・7.2・7.3・10.3）。v1.4新設 

付録B. ポリシーサマリ 

IP登録・削除ポリシー 

申請経由のIPはSource=Requestedで登録。ホスト名入力時はDNSにAレコード+PTRを作成、未入力時はDNS登録スキップ。 

ARP検出のIPのうち固定IP範囲内のもののみSource=AutoDetectedで登録し、DNSには登録しない。動的プール内の検出IPは登録しない。 

Source=AutoDetectedかつLastSeenAtが1ヶ月以上前 → 削除（Cooldown 30日へ移行）。 

Source=Requestedは明細（IPRequestItems）単位でNotificationStageを段階更新（3ヶ月：申請者、6ヶ月：申請者+Manager、12ヶ月：申請者+Manager。同一申請・同一段階は集約して1通）後、12ヶ月でIPAM+DNS削除・明細Status=Archived（全明細Archivedで親もArchived）。通知先取得失敗等の異常系のみnkis-network@nkc.co.jpへ通知。 

削除されたIPはSource=Cooldownで30日間IPAMに保持。30日経過後に物理削除（空きプールへ復帰。実効：30日保持＋確認1日＝実効31日。7.4のCooldown満了サブフロー）。期間中にARP応答を検知した場合はSource=AutoDetectedとして復帰（Requested由来はnkis-network通知）。（v1.4追記） 

削除猶予（1ヶ月/3ヶ月/6ヶ月/12ヶ月およびCooldown 30日）の経過日数は、当該セグメントの収集経路が有効であった日数でカウントする。ARP観測が抑止されていた期間（Failed機器由来・未カバー由来の削除スキップ期間）は猶予を消費せず、SkippedDaysにより経過日数を補正する（6.3・7.4・6.8の日数計算規約）。（v1.4追加。要件変更＝A-1） 

DNS登録ポリシー 

登録ゾーン：ad.nkc.co.jp（AD統合DNS）。 

FQDN構成：<ホスト名>.ad.nkc.co.jp。 

Aレコード作成時に-CreatePtrオプションで逆引きPTRも自動生成。 

TTL：3600秒（社内統一）。 

対象：Source=Requestedかつホスト名入力ありのIPのみ。 

ユーザ操作ポリシー 

申請：Power Appsから随時可能。即時自動払い出し。 

申請変更・削除：ITポータル経由でIT部門に手動依頼。 

サーバ移行に伴うIP事前確保：ITポータル経由でIT部門が手動実施。 

ホスト名変更・DNS切替：IT部門の手動作業（本システム対象外）。 

エラーハンドリングポリシー 

サイレントエラー禁止：全例外は必ずログ記録＋通知経路（申請者 or nkis-network）に到達させる。 

登録・払い出し時のIP重複は100%検知：IPAM登録・払い出し・ARP検出の3経路で登録重複チェック、検知時は即時nkis-networkへ通知。運用中のIP競合疑い（Source=RequestedのIPで登録済みと異なるMACを検出）はMAC上書きと同時にnkis-networkへ通知する。 

RetryCount上限3回：上限到達でStatus=Failed確定＋nkis-networkへエスカレーション通知。 

Worker多重起動防止：ミューテックスまたはロックファイル方式を実装要件に明記。 

ARP収集セーフティ：機器単位パターンβ採用。72時間連続失敗でFailed遷移通知・Failed機器担当セグメントの自動削除スキップ。 

※ 05 E区分の確定文言10件へ差替え。旧一覧10項目全体を見え消しで包み、新10件を確定文として置く。 ※ 依頼者確定：E①は「削除の実害は防止される」へ復元（意味変質の是正）。12ヶ月境界の限定句は付さない。 ※ 依頼者確定：旧項目8後段の創作文（監視スクリプト停止を#20で検知）は単純削除、どこにも書かない。 ※ 依頼者確定：旧項目10（初期稼働閾値延長のトレードオフ）は当一覧から削除し、10.2本文へ参照1文として残す（後掲）。 

既知の制約（v1.4新設） 

外部発注前レビュー（3-1／3-2／3-3）および複合故障シナリオ（CC-1〜CC-8）で確認された、本設計が仕様として受容する制約を一覧化する。いずれも影響が限定的または運用・監視で回復可能と判断したものである（詳細は該当節）。（v1.4新設） 

収集経路の非保護窓：ARP収集機器の障害検知（72時間連続失敗）が成立するまでの間、当該セグメントは削除スキップの保護外である。この窓で日数境界（90/180/365日）を跨いだ個体には、リマインダの誤送信が最大1回生じ得る（削除の実害はSkippedDays補正・緩衝・Cooldownで防止される）。 

物理削除後の再出現IP：廃止セグメントで物理削除後に再出現したIPは、IsActive=falseの間は台帳化されない。対策は廃止手順（10.6）の遵守であり、回収経路はIsActive=true復帰時の次ARPサイクルでの自己回復のみである。 

Error滞留中の段階跨ぎ：NotificationStage=Errorが日数境界を跨いで滞留した場合、復帰時の段階通知が最大1段階欠落し得る（12ヶ月削除通知は次段階遷移のクリアにより保証される）。 

人手フラグ先行前の窓：範囲変更でRangeChangePendingの先行設定を怠った場合、同期Workerのセーフティネット検知までの最大30分間は払い出し抑制が効かない。 

代表サーバ障害中の変更：障害中にパートナーサーバ側で行ったスコープ変更は、運用規定（10.3）でのみ保護され、技術的には検知されない。 

走査開始スナップショットの1夜窓：自動削除の除外判定は走査開始時点の状態で確定し、走査中の機器状態変化は翌日の実行から反映される。 

SharePoint障害中の許容再送：SharePoint書込障害の継続中は、同一段階の通知が複数回届き得る（送信済み記帳が成立した明細は再送されない・有界）。 

完了通知の欠落回復：通知フローの最終失敗による完了通知の欠落は、自動再送せず、監視スクリプトによる24時間以内の検知と手動再送で回復する。 

縮小前チェックの非代替性：固定IP範囲の縮小前のRequested/Cooldown残存確認（10.3）は人手チェックであり、技術制御では代替できない。 

Cooldownの実効期間：Cooldownの物理削除は「30日保持＋確認1日」で実行される（公称30日に対し実効31日）。 

廃止セグメントの#15恒常発報とSkippedDays累積：廃止セグメント（10.6-1の手順で機器行を削除したセグメント）は恒久的に未カバー判定となり、自動削除スキップ通知（付録F#15）が日次で発報し続け、SkippedDays／LastSkipDateへの加算も継続する。10.6-1の安全な廃止手順（残存IP棚卸し・処置後に撤去、最終的にレコード・レンジを手動削除）を最後まで遵守した場合、当該セグメントは走査対象から外れ#15も停止する。手順を(5)まで完遂せずIsActive=falseのまま滞留させた場合、#15発報とSkippedDays累積が継続する。手順未遵守で残存IPがある場合、当該IPは削除保護され続ける。（10.6-1・7.4） 

SkippedDaysの生涯累積：SkippedDays補正はセグメント生涯にわたる累積であり、リセットされない。観測抑止が解消した後に登場した新規IPに対しても、過去の累積日数分だけ削除・リマインダ猶予が延伸する（方向は安全側＝早すぎる削除は起きない）。長期運用では公称値（1ヶ月／3ヶ月／6ヶ月／12ヶ月）から乖離し得る。（6.3・7.4・10.6/11.3の運用リセット判断） 

復帰部分失敗直後の恒久沈黙：復帰処理の部分失敗直後に満了サブフローの条件(3)が恒久不成立となるCooldown残骸は、検知網の外で滞留し得る（方向は安全側＝誤削除は起きない）。発生確率は極小であり、10.7の手動棚卸しで回収する。（7.4満了サブフロー・7.3(a)・10.7）（7.4・付録A） 

付録C. 事前調査チェックリスト 

C.1 DHCPスコープの除外範囲設計の一貫性 

「動的プール（スコープ範囲−除外範囲）内に固定IP設定機器が存在しないこと」および「固定IP範囲（セグメントCIDRのホスト範囲−動的プール−予約IP）に既存固定機器が収容されていること」を全DHCPスコープで確認する。全スコープの除外範囲一覧を成果物として提出すること。全スコープの「除外範囲一覧」を成果物として提出すること。 

（3）ペア間のスコープ定義整合（範囲・除外範囲）を全件確認・是正すること。検出済み不一致1件（奉賢工場172.31.140.0のEndRange：nkdc4=.219／nkdc5=.229）は正値を確定のうえ是正し、結果を本項の成果物に含めること（v1.2追加）。 

C.2 Meraki Dashboard APIのレート制限 

全MX機器を1回のARP収集サイクル（1〜3時間）内でスキャンできるか確認する。Meraki組織数/ネットワーク数/MX台数の一覧＋既存API利用の有無を提出すること。 

C.3 海外DHCPサーバへの疎通確認 

Azure VM → 海外オンプレDHCPサーバ2台の通信が成立するか確認する。疎通確認結果および必要なFW穴開け依頼を提出すること。 

C.4 Power Automateの月間実行数がE5範囲内で収まるか 

本システム用のPower Automateフローが、E5ライセンスのPower Platformリクエスト制限内で運用できるか確認する。専用サービスアカウントの発行可否＋テナントレベル制限の有無を提出すること。 

C.5 SharePointバージョン履歴保持期間が監査要件を満たすか 

IPRequests等に対して社内規定・法規制で求められる保存期間を満たせるか確認する。必要保管期間＋現行設定で足りるか否か＋不足なら追加設計要否を提出すること。 

C.6 ARP収集対象機器へのSNMP到達性・機器側設定（v1.1追加） 

Azure VM（Worker）から全ARP収集対象機器へのSNMP（UDP/161）到達性、および機器側の許可設定（SNMP ACL/コミュニティ/SNMPv3ユーザ）の投入計画を確認する。対象機器一覧（ベンダ別台数・担当セグメント）を成果物として提出すること。機器側の設定投入は発注元側作業とする。機器一覧の項目には、各機器のDeviceType（CiscoIOS/FortiGate/YamahaRTX/MerakiMX）、およびMeraki機器のMerakiOrgId/MerakiNetworkIdを含める（ArpDeviceStatusの初期投入データとして流用する。6.9・10.6）。（v1.4追加） 

付録D. 論点判断一覧（v1.0反映済み） 

v1.0で反映した全18件の論点判断を一覧化する。 

# 

論点 

判断 

1 

A-3-1 命名規則違反Failedの発生経路 

Worker側の分類を削除（Power Apps側バリデーションを信頼） 

2 

A-4-1 IPAMロールバック失敗時の扱い 

Status=Failed・ErrorMessage詳細記録・nkis-networkへ緊急アラート（手動対応） 

3 

A-6-1 Graph APIリトライ失敗後の処理 

IPAMロールバック→Status=Pending→次サイクル再処理。RetryCount上限3でFailed確定+nkis-network通知 

4 

A-10-1 Manager/UPN取得失敗通知のダイジェスト化 

即時通知継続（ダイジェスト化なし） 

5 

A-5-1 Worker死活監視 

監視スクリプトを1日1回実行、前回実行結果チェック、失敗/未実行時はnkis-networkへ通知 

6 

O-6-1 Worker多重起動防止 

ミューテックスまたはロックファイル方式を実装要件に明記 

7 

B-2-1 空きIP閾値の境界定義 

残り20件以下で発報 

8 

B-3-1 自動削除経過月の境界定義 

日数ベース（30/90/180/365日）・JST深夜実行基準 

9 

B-6-1 同一IP異MAC検出時のマージロジック 

最新タイムスタンプ優先でMAC上書き・通知なし 

10 

O-1-1 Segmentsリスト直接編集バリデーション 

人手確認のみ（ネットワークアドレス誤り・CIDR形式混同に注意喚起を運用手順書に記載） 

11 

O-2-1 IPAMカスタムフィールド復旧手順 

運用手順書（外部発注先成果物）に復旧スクリプトとして含める 

12 

O-3-1 DHCPスコープ⇔Segments突合監査 

セグメント同期Worker実行時に突合チェック追加、漏れ検知時はnkis-networkへ通知 

13 

O-4-1 CIDR変更時の整合性ずれ対応 

運用ルールで禁止：変更不可・必要時はレコード新規作成+旧IsActive=false 

14 

A-12-1 AutoDetected重複状態での申請運用ガイド 

払い出し完了通知メール本文に「通知された新IPに手動設定変更」を明記（10.1節強化） 

15 

O-8-1 ユーザ単位の申請ガバナンス 

初期実装なし（空きIP閾値アラートで間接検知。問題化したら後追い） 

16 

I-10 自動削除時のIPRequests Status遷移 

IPRequests.StatusにArchived値を追加。自動削除実施時に設定（履歴保持） 

17 

I-11 クールダウン実装方式 

案B継続（30日）＋IPAMにSource=Cooldown値追加。30日経過後に物理削除 

18 

I-13 DhcpScopeExists=falseの閾値アラート対象 

全セグメント走査に変更（Segments全件・IPAM使用数照会・アラート判定を全セグメント対象化） 

※ v1.1での変更：A-3-1はWorker側のホスト名再検証を復活（防御的二重チェック）、B-6-1はSource=Requestedの異MAC検出時に競合疑い通知を追加、I-10は段階管理をIPRequestItems（明細）単位へ変更。判断経緯の記録として表本体はv1.0時点の記載のまま保持する。 

付録E. 実装規約（セキュリティ・コーディング）（v1.1新設） 

実行アカウント：gMSA不可の場合は通常サービスアカウントとし、対話型ログオン拒否・最小権限・タスクスケジューラ登録時以外のパスワード保存禁止を条件とする。 

秘密情報の保管：SNMP資格情報、Meraki APIキー、Graph API証明書秘密鍵、SMTP設定値のスクリプト・設定ファイルへの平文記載を禁止する。PowerShellはSecretManagement＋SecretStoreまたはDPAPI（Export-Clixml）、PythonはDPAPI（win32crypt）または資格情報マネージャを使用し、実行アカウントに紐付く保護とする。 

SNMP：SNMPv2cを標準とする。コミュニティ名は全機器共通（全社共通1系統）とし、例外機器が生じた場合のみDeviceIdをキーにSecretStoreへ個別登録する。機器側ACLは別設計書の管理範囲（作業者=発注元）のため本書には記載しない（v1.3改訂）。 

コーディング：例外の握り潰しを禁止する（全例外でログ記録＋通知経路への到達を保証）。PowerShellはWindows PowerShell 5.1（IPAMモジュール互換）でPSScriptAnalyzer既定ルールに適合させる。PythonはPython 3.11以上、venv＋requirements.txtで依存を固定する。戻り値・終了コードで成否を判定可能とすること。 

通知抑制状態のローカル保持：通知の重複抑制に用いる状態（例：代表DHCPサーバ照会失敗の1日1回抑制記録）は、SharePointリストへ列追加せずWorkerローカルに保持してよい（喪失時は再通知となるのみで安全側）。ただし削除判定・除外判定に影響する状態のローカル保持は禁止する（本文8.4と整合）。（v1.4追加） 

証明書・キー管理：Graph API証明書の有効期限監視（期限60日前にnkis-networkへ通知）と更新手順、Meraki APIキーのローテーション手順を運用手順書に定義する。 

付録F. 通知一覧（v1.1新設） 

# 

イベント 

宛先 

送信経路・契機 

1 

申請受付 

申請者 

Power Automate（親レコード作成トリガ） 

2 

払い出し完了 

申請者 

Power Automate（親Status=Assigned/PartiallyFailed）。送信は7.4の通知フロー共通規約に準拠し、CompletionNotifiedAt未設定を条件に送信・送信成功確認後に更新（v1.4契機明確化） 

3 

払い出し失敗 

申請者 

Power Automate（明細Status=Failed。文面は8.5）。FailureNotifiedAt未設定を条件に送信・送信成功確認後に更新。フロー並列度1（v1.4契機明確化） 

4 

3ヶ月リマインダ 

申請者 

Power Automate（明細NotificationStage。集約送信・並列度1・NotificationSentAtガード。7.4） 

5 

6ヶ月リマインダ 

申請者+Manager 

同上 

6 

12ヶ月削除通知 

申請者+Manager 

同上 

7 

通知異常（UPN/Manager取得失敗等） 

nkis-network 

Power Automate（NotificationStage=Error）。独立トリガフローとせず、#4〜#6の送信フロー自身がエラー捕捉時にError書込と本通知を実施する（7.4・v1.3確定） 

8 

MissLog検知 

nkis-network 

Power Automate（MissLog作成トリガ）。OfficeLocation非空の未マッチのみ（空値は記録のみ・通知なし。3.1・10.6）（v1.4契機明確化） 

9 

空きIP閾値（20件以下） 

nkis-network 

セグメント同期Worker→SMTPリレー 

10 

DHCP⇔Segments突合漏れ 

nkis-network 

セグメント同期Worker→SMTPリレー 

11 

ARPカバレッジ漏れ 

nkis-network 

セグメント同期Worker→SMTPリレー（CoverageNotifiedAtで1日1回抑制。7.2） 

12 

ARP機器Failed遷移/Failedリマインダ 

nkis-network 

ARP収集Worker→SMTPリレー 

13 

IP競合疑い（Requested異MAC） 

nkis-network 

ARP収集Worker→SMTPリレー 

14 

Cooldown中復帰（Requested由来） 

nkis-network 

ARP収集Worker→SMTPリレー（復帰処理はIPAM反映スクリプトが実施。7.3・7.4） 

15 

削除スキップ（日次） 

nkis-network 

自動削除Worker→SMTPリレー。Failed機器由来・未カバー由来・レンジ非所属由来を事由別に記載し、スキップ継続日数（SkippedDays）を付す（7.4・8.5）（v1.4契機明確化） 

16 

IPAMロールバック失敗（緊急） 

nkis-network 

IP払い出しWorker→SMTPリレー 

17 

RetryCount上限到達 

nkis-network 

IP払い出しWorker→SMTPリレー 

18 

Processing滞留回収 

nkis-network 

IP払い出しWorker→SMTPリレー 

19 

DNS環境不備（逆引きゾーン欠落等） 

nkis-network 

IP払い出しWorker→SMTPリレー 

20 

Worker死活監視失敗・未実行 

nkis-network 

監視スクリプト→SMTPリレー。完了通知欠落・親Status=Pending滞留（24時間超）の検知通知も本経路で送信する（10.4）（v1.4契機拡張） 

21 

VMハートビート停止 

nkis-network 

Azure Monitor 

※ ユーザ向け通知（#1〜6）の文面テンプレートは別途ドラフトレビューで確定する（13章）。SharePointトリガは列単位の変更検知を持たないため、各フローはトリガ条件＋送信済み判定（NotificationSentAt等）で多重発火を防止し、NotificationStage連動フローは並列度1で構成すること。 

付録G. 責任分界表（RACI）（v1.3新設） 

11章「貴社」を「発注元（NKC）」に全置換したことに伴い、契約前提となる主要作業の主体を一覧化する（Q37確定）。11章・13章・付録Cの全作業を対象とし、詳細な期限区分は各該当節を参照。 

作業項目 

主体 

備考 

サブスクリプション・VNet/サブネット・NSG・命名規則の準備 

発注元 

課金・ネットワーク境界はガバナンス事項のため外部委譲しない（Q39） 

Azure VM作成〜OS設定・IPAM有効化・スケジューラ登録 

受注側 

11.1工数どおり（Q39） 

検証用SharePointサイト・検証用DHCPスコープ・DNS検証用サブゾーンの用意 

発注元 

専用検証環境は新設しない（Q40） 

受注側要員への期限付きアカウント付与・既設VPN接続 

発注元 

Q40 

IPAM管理用GPO作成 

発注元 

受注側は定義書・手順書・検証を提供（Q41） 

Entra IDアプリ登録の管理者同意 

発注元 

セキュリティ部門の既存承認プロセスに載せる（Q41） 

ArpDeviceStatus初期データの一覧作成（機器一覧。DeviceType/MerakiOrgId/MerakiNetworkIdを含む） 

発注元 

C.6成果物の機器一覧を流用（Q44・10.6）。DeviceType・MerakiNetworkIdは収集の駆動キーのため一覧作成時に確定させる（6.9・7.3）（v1.4：既存「一覧作成」行に項目を追記。(g)-2） 

ArpDeviceStatus初期データのSharePoint投入 

受注側 

CSVツールを拡張して対応（+0.3人日目安。Q44） 

Segmentsマスター初期投入作業 

発注元 

本工数に含まない（11.1既定） 

付録C事前調査（C.1〜C.6） 

発注元 

契約締結前・Week2末までの期限別（Q43は保留） 

WorkerサーバIPの社内SMTPリレー許可元登録 

発注元 

13章参照 

対象NW機器へのSNMP許可設定（ACL/コミュニティ）の投入 

発注元 

付録C.6参照 

DHCPペア間スコープ定義不整合の是正 

発注元 

付録C.1参照 

gMSA利用可否の社内調整（KDSルートキー整備） 

発注元 

13章参照 

Power Automate送信元メールボックスの確定 

発注元 

13章参照 

本番移行の拠点段階公開判断・初期削除閾値の切替判断 

発注元 

段階的サービスイン・初期稼働期間の閾値運用の判断主体（10.2・11.2）。v1.4新設（要件変更＝A-3） 

 