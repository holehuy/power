**Hệ thống tự động cấp phát địa chỉ IP cố định**

**Tài liệu thiết kế sơ bộ**

**V1.4**

2026-07-13 / Rev.1.4

Dùng cho đặt hàng bên ngoài Bản cuối cùng

# Lịch sử sửa đổi

<table style="width:100%;">
<colgroup>
<col style="width: 5%" />
<col style="width: 0%" />
<col style="width: 8%" />
<col style="width: 0%" />
<col style="width: 84%" />
<col style="width: 0%" />
</colgroup>
<thead>
<tr>
<th><strong>Phiên bản</strong></th>
<th colspan="2"><strong>Ngày</strong></th>
<th colspan="2"><strong>Nội dung thay đổi chính</strong></th>
<th></th>
</tr>
<tr>
<th>0.1</th>
<th colspan="2">2026-04-24</th>
<th colspan="2">Bản đầu tiên（draft）</th>
<th></th>
</tr>
</thead>
<tbody>
<tr>
<td colspan="2">1.0</td>
<td colspan="2">2026-04-24</td>
<td colspan="2">MACバインド方式を廃止し手動IP設定方式へ変更。ARP自動検出・自動登録機能、段階的自動削除ポリシー、DNS自動登録、ARP収集のPython+SNMP+Meraki API化、Windows IPAMカスタムフィールド設計を追加。ホスト名任意化・DNS登録スキップ対応、UIカスケードを3段化、地域マスター粒度を都道府県/国に変更、Segmentsリストを一次情報源化、OfficeLocationMap/MissLog追加、ホスト名命名規則確定、承認フロー/削除機能/終了予定日を廃止、IPAM+WorkerをAzure VM上で同居する構成へ変更、バックアップ構成を追加、事前調査チェックリスト（付録C）を追加。レビューによる仕様変更。ARP収集頻度を1時間ごとに変更。セグメント同期Worker頻度を30分ごとに変更。一括払い出し機能を追加（最大20件、親子構造）。空きIP閾値アラート機能を追加（閾値20件、1日1回）。削除通知にManager追加・異常系のみIT部門通知。多言語切替をスコープ外（将来拡張）に追加。認証基盤の表記修正。ライセンス要件を補強。外部レビューによる仕様変更。一括払い出し対応（IPRequestItems分離・BatchSize追加）。セグメント同期Workerの申請タイトル・デバイス種別廃止。申請画面の注意事項エリア追加。ArpDeviceStatusリスト追加（SharePointリスト6本化）。IPRequests.RetryCount/NotificationStage/Archived追加。IPRequestItems.RetryCount追加。セグメント同期Worker頻度修正（日次→30分ごと）。自動削除フロー更新（ARP機器単位セーフティ・NotificationStage経由通知・Archived遷移・Cooldown実装）。ARP収集フロー更新（ArpDeviceStatus Upsert・72h連続失敗検知）。エラーハンドリング方針強化。18件の論点判断を全反映。工数35.5人日に更新。</td>
</tr>
<tr>
<td colspan="2">1.1</td>
<td colspan="2">2026-07-09</td>
<td colspan="2">外部発注前レビュー指摘26件および追加ヒアリング（H1〜H8）の結果を反映。【算出式是正】固定IP範囲＝セグメントCIDRのホスト範囲−動的プール（スコープ範囲−除外範囲）−予約IPに是正（7.2。従来式は動的プールそのものを指すため逆）。付録C.1の確認観点を動的プール内の固定設定機器有無に変更。【ARP範囲限定】ARP自動登録・LastSeenAt更新を固定IP範囲内に限定（2.1/3.1/7.3）、UsageCount集計を固定IP範囲内に統一（6.3/7.2）。【IPAMレンジ同期】セグメント同期WorkerにIPAMレンジ作成・同期を追加（7.2/8.3）、CSVツールをレンジ初期投入対応に拡張。【削除通知の明細化】NotificationStage/ArchivedをIPRequestItems単位へ移動、NotificationSentAt列新設、同一申請・同一段階の集約送信（並列度1）を規定（6.4/6.5/7.4）。親RetryCount廃止（明細へ一本化）。【払い出しフロー】LastSeenAtを払い出し時に初期化（6.8/7.1）、Processing滞留回収（30分）を追加（7.1/8.4）、RequestIdを決定的採番（REQ-yyyymmdd-親アイテムID）化・明細参照をParentItemIdへ変更（6.4/6.5/7.1）、Worker側ホスト名再検証を復活（7.1）。【競合検知】Requested IPの異MAC検出時の競合疑い通知を追加、「IP重複100%検知」の適用範囲を登録・払い出し時に明確化（7.3/8.4/付録B）。【Cooldown】全削除に30日Cooldown適用、期間中復帰はAutoDetected扱い（Requested由来は通知）と確定（7.4/付録A/B）。【通知経路】Worker発アラートは社内SMTPリレー経由、manager取得はPower Automate（Office 365 Usersコネクタ）責務と確定（7.4/8.3/8.4/8.5）。付録F「通知一覧」新設。【セキュリティ】付録E「実装規約」新設（gMSA第一候補・秘密情報保管・SNMPv3優先・例外処理規約・証明書期限管理）。DNS書込権限のセキュリティ部門承認済みを明記（9.1）、IPアドレス追跡（ログオンイベント突合）を削除（9.3）。【ARP収集】ArpDeviceStatusを機器マスターと位置付け（冗長ペアは代表1台のみ登録）・マスタメンテ対象化（6.9/10.6）、ARPカバレッジ突合チェック追加（3.1/7.2）、ipNetToMediaTableフォールバック・LastSeenAt書込24hスロットリング・IPAM反映のPowerShellスクリプト経由化を明記（7.3）。【その他】リスト本数を7本に訂正、閾値クリア条件を21件以上に修正、逆引きゾーン不備時ロールバック＋通知追加、インデックス列・処理規模前提（年間約200件）明記、Azure Monitorハートビート監視追加（10.4）、復旧時三者整合手順の要件化（10.5）、SegmentId＝SharePointアイテムIDと定義、StaticIpRangeRaw正本化、付録C.6（SNMP到達性・機器側設定）追加、11.3「発注条件」新設。工数35.5→39.5人日。</td>
</tr>
<tr>
<td colspan="2">1.2</td>
<td colspan="2">2026-07-09</td>
<td colspan="2">外部発注前レビュー指摘のクローズ反映（親Status集約規則・削除通知段階管理の是正・冪等性再開設計・DHCPフェールオーバー構成明記・IsActive処理規定・IT手動対応手順新設ほか）</td>
</tr>
<tr>
<td colspan="2">1.3</td>
<td colspan="2">2026-07-10</td>
<td colspan="2">設計書v1.2.1に対する質問管理表（55件）の回答確定を反映（回答済47件を反映、実値・方針の一部保留8件は次版で反映予定）。【Worker実行タイミング確定】IP払い出しWorker実行間隔を5分固定に確定（4.2/7.1）。VM/各Workerの起動時刻・タイムゾーン（JST）を確定：ARP収集=毎時00分、セグメント同期=毎時15分/45分、自動削除Worker=02:00、監視スクリプト=07:00（2.2/4.2/7.2/7.3/7.4/10.4）。【パラメータ確定】Graph API等一時エラーの指数バックオフ（初期2秒・倍率2・対象429/408/5xx/接続タイムアウト）、SNMP収集パラメータ（タイムアウト5秒・リトライ2回・並列度1）、イベントログ・ファイルログの保持設定（イベントログ512MB上書き・ファイルログ日次ローテーション90日保持）、LastSeenAtのタイムゾーン形式（JSTオフセット付きISO 8601）を確定（7.3/8.3/8.4）。SharePointアクセス障害の「継続失敗」を連続5実行サイクルに確定（10.4）。【5.2/5.4/5.5】ホスト名連番生成ボタンを実装対象外に変更（一括払い出し機能自体は存続）。拠点ドロップダウンはSitesリスト新設せずOnStartでのSegmentsコレクション化・Distinct方式に確定（データ行制限2000へ引き上げ）。確認画面の「IP」表示を削除。【データモデル確定・列追加】StaticIpRangeRaw・TargetSegmentsのJSON/格納形式を確定。ItemId列を廃止しSharePointアイテムIDを一意キーに統一。Segments.DnsServers列、ArpDeviceStatus.MerakiOrgId/MerakiNetworkId/DeviceType列、IPAMカスタムフィールドCooldownStartedAt（4項目目）、親IPRequests.CompletionNotifiedAt、明細IPRequestItems.FailureNotifiedAt・ErrorCategory（DnsDuplicate/NoFreeIp/NamingRule/SystemError/DnsDuplicateDynamicの5値）を新設（6.1/6.3/6.5/6.8/6.9）。【分岐・処理確定】RequestId決定的採番の基準を親レコードCreated（JST）に統一。空きIP候補3件枯渇時はRetryCount経由でPendingへ戻す既存経路に合流。即時Failed対象（空きIPなし/DNS重複/命名規則違反）とリトライ対象を分類。親作成後の明細部分失敗時の処理（UI側・Worker側の二重防壁）を確定。同一申請内ホスト名重複はPower Apps送信時バリデーションで排除。DNS重複チェックに動的登録レコード区分（DnsDuplicateDynamic）を追加（7.1/8.5）。ARPカバレッジ突合漏れセグメントを自動削除スキップ対象に追加。固定IP範囲縮小・消滅時の扱い（レンジ縮小反映・範囲外IPは手動判断）、DhcpScopeExists=falseセグメントのUsageCount更新責務を確定（7.2）。MissLog記録契機（申請送信時）・OfficeLocation空値の扱いを確定（5.4/7.1）。NotificationStage=Errorの書込主体を確定（7.1）。DHCPスコープ⇔Segments突合の検知対象3パターンを確定（7.2）。【セキュリティ・実装規約】SNMPはv2c標準に変更（付録E改訂、SNMPv3優先の記述を削除）。IPRequestItemsの一般ユーザ権限を確定（9.1）。Power Apps/Automate所有の共有サービスアカウントは既存E5付与済みアカウントを流用（9.2、担当チーム確認結果待ちの条件付き確定）。【契約・責任分界】「貴社」の表記を「発注元（NKC）」に全置換のうえ、11章・13章・付録Cの全作業を主体列付き責任分界表（RACI、付録G新設）として整理。Azure VM構築主体（サブスクリプション/VNet等=発注元、VM構築以降=受注側）、検証環境（本番テナント内に検証用サイト・スコープ・DNSサブゾーン）、GPO作成・Entra IDアプリ登録の管理者同意（発注元実施）、ArpDeviceStatus初期データ投入分担、Segments総件数（約1000件）を確定（2.2/9.2/10.6/11章/13章/付録C/付録G）。【受入基準】「30分以内」を努力目標（SLO）とし受入基準から除外、参考値実測報告を追加。「3名体制で継続運用可能な複雑性」は受入判定対象外とし運用手順書レビュー承認で充足とみなす。時間依存動作の受入検証は日数閾値の外部パラメータ化・下限7日ガードで確定。Entra IDユーザ単位追跡はシステム起因変更をサービスアカウント名義+RequestId/イベントログ経由の間接追跡で充足とみなす旨を注記（3.2/7.4/9.3/11.3）。【付録C】DHCPペア間スコープ定義不整合（奉賢工場172.31.140.0のEndRange）の是正結果を反映（C.1）。実値のみ保留（8件）：DNS書込先サーバ実値（FQDN）、SMTPリレー実値、C.1/C.6以外の事前調査完了時期、通知文面提供時期、PSScriptAnalyzer「重大」の対象Severity、ARP収集1サイクル実測の合格閾値、テスト観点表承認タイミング、Worker発アラートメール文面様式は、契約締結前後の別途確定事項として次版で反映する。</td>
</tr>
<tr>
<td colspan="2">1.4</td>
<td colspan="2">2026-07-13</td>
<td colspan="2">外部発注前レビュー（3-1／3-2／3-3）で抽出した38件超の指摘、および複合故障シナリオ（CC-1〜CC-8）・レース条件レビュー（5並列Worker）の結果を、確定対策仕様（05）に基づき一括反映した。<strong>【要件変更（発注元承認済み・5件）】</strong>・<strong>A-1 猶予日数の観測日数カウント</strong>：削除猶予の経過日数（1ヶ月/3ヶ月/6ヶ月/12ヶ月・Cooldown 30日）は、当該セグメントの収集経路が有効であった日数でカウントする（ARP観測が抑止されていた期間は猶予を消費しない。SkippedDays補正）。反映先＝付録B「IP登録・削除ポリシー」。・<strong>A-2 カバレッジ判定の書き分け</strong>：自動削除スキップ用の除外判定を、自動削除Workerの実行時再計算・IsActive非依存へ変更する（通知用のARPカバレッジ突合は従来どおりIsActive=trueのみを対象）。反映先＝3.1・7.4先頭処理・7.2。・<strong>A-3 初期稼働期間の削除閾値延長</strong>：既存手動設定固定IPの一括AutoDetected登録に伴う一斉Cooldown移行を回避するため、初期稼働期間はAutoDetected自動削除の日数閾値を初期延長値で運用する（外部パラメータのため実装変更不要）。反映先＝10.2・11.2・11.3・付録G。・<strong>A-4 完了通知欠落の手動回復への縮退</strong>：通知フロー最終失敗による完了通知の欠落は自動再送せず、監視スクリプトによる24時間以内の検知＋手動再送で回復する。反映先＝10.4・9.1・11.3・付録B既知の制約 項目8（E⑧）。・<strong>A-5 Cooldown実効31日</strong>：Cooldownの物理削除は「30日保持＋確認1日」で実行する（公称30日に対し実効31日）。反映先＝付録A・付録B・7.4 Cooldown満了サブフロー。<strong>【データモデル】</strong> Segmentsに7列追加（CoverageStatus／CoverageCheckedAt／CoverageNotifiedAt／RangeChangePending／LastSkipDate／SkippedDays、およびCapacityTotal説明追記）。<strong>DnsServers定義行の誤混入行の是正</strong>：本行は履歴レコードではなくデータモデル定義行が改訂履歴表内へ物理的に誤混入したものであるため、当該行に取り消し線を付し、定義文を不変のまま6.3表（SubnetMask直後）へ移設した。IPAMカスタムフィールドにCooldownStartedAt定義行を追加（6.8）。IPRequests／IPRequestItems／ArpDeviceStatusの各列に書込主体・契機・参照先を明記（6.4/6.5/6.9）。<strong>【削除判定】</strong> 除外セグメント判定を走査開始時点の実行時再計算へ変更（IsActive非依存）。SkippedDaysによる経過日数補正を導入。Cooldown満了サブフロー（＋31日方式）を新設。7.4のIP単位述語（範囲外化IPの削除保留）を新設。スキップ解除時の緩衝を新設。復帰正典（クリア・保持フィールドの網羅列挙）を確定（7.4/7.3/10.7）。<strong>【範囲変更制御】</strong> RangeChangePendingによる払い出し抑制・新規AutoDetected登録保留・滞留検知通知を3Worker横断で新設（7.1/7.2/7.3/10.3/5.4）。<strong>【通知】</strong> 7.4に通知フロー共通規約（フロー並列度1・送信成功確認後にガード列更新・at-least-once前提の冪等許容再送）を新設し、付録F #2/#3/#7/#8/#14/#15の契機欄を確定。NotificationStageのNotificationSentAtクリア規則を是正（6.5/7.4）。<strong>【排他・冪等】</strong> Worker間排他（IPアドレスキーのエントリ単位ミューテックス）、ロックファイル自動失効規約、周期超過時の挙動、冪等性の総則を8.4へ新設。<strong>日数閾値の外部パラメータ化・下限7日ガードを本文化</strong>（v1.3で確定済みだが本文未反映であったものの是正。改訂履歴側の記述は履歴として正しいため非改訂）。通知抑制状態のWorkerローカル保持許容を規定（8.4・付録E）。<strong>【運用】</strong> 監視スクリプトの検知網を拡張（完了通知欠落・親Status=Pending滞留の24時間内検知／自動再送なし）。セグメント・収集機器の安全な廃止手順、代表サーバ障害中のスコープ変更規定、固定IP範囲の縮小前チェックを新設（10.3/10.4/10.6）。IT部門手動対応のCooldown元値保持義務・復帰正典参照を明記（10.7）。<strong>【文書】</strong> 付録Bに「既知の制約」一覧（10件）を新設（7.4末尾の参照先実体）。付録A用語2件、付録C調査項目2件、付録E実装規約1件、付録G責任分界2行を追加。<strong>【本版で改訂しないもの】</strong> 11.1合計行（追補行の工数値がプレースホルダのため次版で欄整備）、13章（通知文面）、付録D表本体（v1.0時点の判断経緯記録として保持）、5.4地域ドロップダウンのItems定義（v1.4対象外）。実値保留8件は引き続き次版反映とする。</td>
</tr>
</tbody>
</table>

# 1. Mục đích của tài liệu này

Tài liệu này tổng hợp thiết kế sơ bộ của hệ thống cho phép người dùng cuối đăng ký và nhận địa chỉ IP cố định thông qua cổng Web nội bộ, cũng như hệ thống tự động phát hiện và lập sổ quản lý tình trạng thực tế của địa chỉ IP trên toàn bộ mạng công ty.

Chính sách cơ bản là xây dựng frontend trong phạm vi license Microsoft 365 E5, đồng thời triển khai bằng cách phối hợp sử dụng Windows IPAM trên Azure VM và Windows DHCP on-premise hiện có, không phát sinh thêm chi phí license.

Tài liệu này là bản cuối cùng dùng cho đặt hàng bên ngoài, được định vị là tài liệu căn cứ để lấy báo giá và ủy thác thiết kế.

# 2. Phương châm cơ bản・Tiền đề

## 2.1 Phương châm cơ bản

- Việc cấp phát IP cố định không sử dụng MAC bind, tiếp tục vận hành theo cách thiết lập IP thủ công trên thiết bị như trước đây. Không tạo DHCP reservation.

- Windows IPAM được xem là nguồn sự thật（Source of Truth）của sổ quản lý địa chỉ IP.

- Danh sách Segments được xem là Source of Truth của master segment. Quản lý toàn bộ segment bất kể có DHCP scope hay không.

- Đối với segment có DHCP scope, Worker đồng bộ sẽ lấy exclusion range từ DHCP mỗi 30 phút, tính toán dải IP cố định và phản ánh vào danh sách Segments. Các segment không tồn tại scope sẽ duy trì giá trị thủ công.

- Tự động thu thập thông tin ARP mỗi 1 giờ, sử dụng để tự động phát hiện・đăng ký IP chưa biết trong dải IP cố định（IP cố định được thiết lập ngoài quy trình đăng ký）và xác nhận sự tồn tại của IP đã được đăng ký.

- IP được chỉ định hostname thông qua đăng ký sẽ được tự động đăng ký vào DNS nội bộ（ad.nkc.co.jp）dựa trên hostname. Nếu không nhập hostname thì bỏ qua đăng ký DNS.

- IP được phát hiện ngoài đăng ký（Source=AutoDetected）sẽ tự động xóa nếu không phản hồi trong 1 tháng（sau khi xóa, qua Cooldown 30 ngày rồi quay lại pool trống）. IP đã đăng ký（Source=Requested）tuân theo luồng xóa theo từng giai đoạn.

- Không thiết lập luồng phê duyệt. Ngay khi gửi đăng ký, xử lý cấp phát tự động sẽ được thực hiện.

- Không triển khai chức năng xóa dành cho người dùng. Các thay đổi do đăng ký sai hoặc chuyển đổi sẽ do bộ phận IT xử lý thủ công thông qua IT Portal.

## 2.2 Môi trường tiền đề

- Đã cấp license Microsoft 365 E5 cho toàn bộ người dùng thuộc phạm vi áp dụng.

- Sử dụng Entra ID làm nền tảng xác thực.

- Có 4 máy chủ Windows DHCP（2 máy trong nước, 2 máy ở nước ngoài）. Windows Server 2016 trở lên. Đây là hạ tầng hiện có, dự án này không xây dựng mới.

- DNS tích hợp AD. Zone là ad.nkc.co.jp. Reverse lookup zone đã được thiết lập theo từng segment. TTL là 3600 giây（thống nhất trong nội bộ công ty）.

- Vendor của thiết bị mạng thuộc phạm vi: 4 nhóm gồm Cisco Catalyst（IOS）, FortiGate, Yamaha RTX/NVR, Meraki MX.

- Xây dựng mới 1 máy chủ Windows IPAM kiêm Worker server trên Azure VM. Cho máy chủ này join vào domain AD nội bộ.

- Đường kết nối giữa Azure và on-premise（VPN/ExpressRoute）đã có sẵn. Đã có kinh nghiệm vận hành join domain nội bộ.

- Có thể sử dụng SMTP relay server nội bộ（đường gửi email cảnh báo phát từ Worker. Cần đăng ký IP của Worker server làm nguồn được phép gửi. Bổ sung ở v1.1）.

- 4 máy chủ DHCP gồm các cặp trong nước（nkdc1/nkdc2）và nước ngoài（nkdc4/nkdc5）đều có cấu hình DHCP failover, định nghĩa scope được replicate trên cả hai máy chủ trong từng cặp（khảo sát thực tế tháng 7/2026: xác nhận định nghĩa kép của 455 scope trong nước và 10 scope nước ngoài）. Hệ thống này duy trì tiền đề logic “1 segment = 1 định nghĩa scope”, và trong Segments.DhcpServer sẽ đăng ký máy chủ đại diện để truy vấn（scope trong nước = nkdc1, scope nước ngoài = nkdc4）. ScopeId giống nhau trên partner server（nkdc2/nkdc5）không thuộc đối tượng xử lý. Thay đổi thiết lập scope được thực hiện ở phía máy chủ đại diện và phản ánh sang partner bằng failover replication（Invoke-DhcpServerv4FailoverReplication）. Khi máy chủ đại diện bị lỗi, đồng bộ segment sẽ dừng, nhưng danh sách Segments và IPAM range vẫn giữ giá trị đồng bộ lần trước nên cấp phát vẫn tiếp tục（bổ sung v1.2. Chi tiết xem 7.2/10.3/Phụ lục C.1）.

- Từ Worker server phải có thể kết nối tới các thành phần sau: 4 máy chủ DHCP on-premise, DNS tích hợp AD, thiết bị NW thuộc phạm vi（SNMP）, Microsoft Graph API, Meraki Dashboard API.

# 3. Yêu cầu

## 3.1 Yêu cầu chức năng

- Người dùng cuối có thể đăng ký IP cố định từ Web portal（Power Apps）.

- Khi đăng ký, có thể chỉ định segment bằng lựa chọn cascade 3 cấp: Khu vực → Cơ sở → Segment. Hiển thị của từng segment bao gồm CIDR.

- Nhập hostname, mục đích sử dụng, v.v. khi đăng ký. Hostname là thông tin tùy chọn; nếu không nhập thì bỏ qua đăng ký DNS.

- Không nhập MAC address. MAC sẽ được liên kết sau thông qua thu thập ARP tự động.

- Thông tin người đăng ký（họ tên, email, bộ phận, cơ sở）được tự động lấy từ Entra ID.

- Đối tượng đăng ký là toàn bộ thiết bị IT（server, printer, thiết bị NW, PC, thiết bị khác）.

- Tự động đồng bộ thông tin DHCP scope（bao gồm exclusion range）mỗi 30 phút và giữ các record tương ứng trong master Segments luôn ở trạng thái mới nhất.

- Lấy ARP table từ thiết bị mạng của nhiều vendor mỗi 1 giờ.

- Trong các IP được phát hiện bằng ARP, những IP nằm trong dải IP cố định（đối với segment có DhcpScopeExists=false thì là toàn bộ CIDR）và chưa được đăng ký trong IPAM sẽ được tự động đăng ký vào IPAM（Source=AutoDetected）. Các IP được phát hiện trong dynamic pool（dải DHCP scope − exclusion range）không thuộc đối tượng đăng ký hoặc cập nhật LastSeenAt.

- Tự động cấp phát từ IP còn trống, đăng ký vào IPAM（Source=Requested）, và khi có nhập hostname thì tạo bản ghi A và bản ghi PTR trong DNS.

- Tự động thông báo kết quả đăng ký và các loại thông báo（bao gồm thông báo trước khi tự động xóa）cho người đăng ký. Xét đến rủi ro nghỉ việc hoặc chuyển bộ phận, các thông báo liên quan đến xóa sẽ được thông báo theo từng giai đoạn cả cho cấp trên của người đăng ký（lấy từ thuộc tính manager của Entra ID）. Chỉ trong các trường hợp bất thường như không lấy được người nhận thông báo thì mới thông báo cho team network/infrastructure.

- Đối với thông báo xóa, Worker cập nhật cột IPRequestItems.NotificationStage（theo từng dòng chi tiết）, và Power Automate sẽ lấy thay đổi của cột NotificationStage làm trigger để gửi thông báo theo template tương ứng với giá trị（áp dụng phương án B）. Các dòng chi tiết thuộc cùng một đăng ký và cùng một giai đoạn sẽ được gộp lại gửi trong 1 email, và quản lý trạng thái đã gửi bằng cột NotificationSentAt.

- Tự động xóa các IP không phản hồi ARP trong một khoảng thời gian nhất định, tùy theo phân loại. IP trong thời gian Cooldown và việc xóa vật lý khi hết Cooldown cũng thuộc đối tượng áp dụng cơ chế bỏ qua xóa（bảo vệ coverage do thiết bị Failed hoặc do chưa được cover）（chi tiết xem 7.4）. Khi thực hiện tự động xóa, đặt IPRequestItems.Status=Archived và giữ lịch sử（khi toàn bộ dòng chi tiết đều Archived thì IPRequests cha cũng được đặt thành Archived）.（thay thế v1.4）

- Khi gửi đăng ký, nếu không khớp trong OfficeLocationMap（bao gồm cả trường hợp OfficeLocation rỗng）, ghi vào MissLog. Chỉ các trường hợp có giá trị OfficeLocation nhưng không khớp mới gửi email thông báo ngay cho team network/infrastructure（giá trị rỗng chỉ ghi log, không thuộc đối tượng thông báo ngay. xác định ở v1.3）.

- Trong 1 đăng ký có thể cấp phát hàng loạt nhiều IP trong cùng một segment（tối đa 20 IP）. Khi thất bại một phần, phần thành công được xác định, phần thất bại được xử lý là Failed（cho phép thành công một phần）.

- Khi số IP trống theo từng segment còn từ 20 IP trở xuống, gửi email thông báo cho team network/infrastructure（người nhận: nkis-network@nkc.co.jp）. Trong thời gian tiếp tục thấp hơn ngưỡng, gửi thông báo mỗi ngày 1 lần（ngăn thông báo trùng bằng AlertLastNotifiedAt）. Kiểm tra ngưỡng áp dụng cho toàn bộ segment（không phân biệt DhcpScopeExists）.

- Thực hiện kiểm tra đối chiếu DHCP scope ⇔ danh sách Segments khi Worker đồng bộ segment chạy, và khi phát hiện thiếu sót thì thông báo tới nkis-network. Đối tượng phát hiện gồm 3 pattern: (a) scope tồn tại thực tế nhưng chưa đăng ký trong Segments, (b) DhcpScopeExists=true nhưng không có thực thể scope, (c) CIDR không khớp（xác định ở v1.3）.

- Thực hiện kiểm tra đối chiếu coverage ARP（CIDR của toàn bộ Segments có IsActive=true phải được bao gồm trong TargetSegments của một ArpDeviceStatus nào đó）khi Worker đồng bộ segment chạy, và khi phát hiện thiếu sót thì thông báo tới nkis-network（cùng một nội dung chỉ thông báo tối đa 1 lần/ngày. bổ sung v1.1）.

- Làm rõ cách xử lý segment có IsActive=false（bổ sung v1.2）: không hiển thị trên UI đăng ký, không đăng ký AutoDetected mới, không kiểm tra ngưỡng IP trống và không đối chiếu coverage ARP; mặt khác vẫn cập nhật LastSeenAt cho IP đã đăng ký（điều kiện là đã đăng ký trong IPAM và ngoài dynamic pool, không đưa IsActive vào điều kiện）và vẫn thuộc đối tượng tự động xóa（vừa tránh xóa nhầm IP đang hoạt động, vừa thu hồi IP không cần thiết）. IPAM range không bị xóa ngay cả sau khi IsActive=false. Việc loại trừ phía đăng ký được triển khai ở nhánh (c) của 7.3. Việc cập nhật LastSeenAt và khôi phục từ Cooldown cho IP đã đăng ký vẫn tiếp tục không phụ thuộc IsActive（sự bất đối xứng giữa đăng ký và cập nhật là thiết kế có chủ đích để tránh xóa nhầm）.（bổ sung v1.4）

- Quản lý trạng thái thiết bị thu thập ARP bằng danh sách ArpDeviceStatus. Khi thất bại liên tục 72 giờ, gửi thông báo chuyển trạng thái Failed tới nkis-network, và các segment do thiết bị Failed phụ trách sẽ được bỏ qua tự động xóa. Các segment chưa được cover phát hiện trong kiểm tra đối chiếu coverage ARP（segment không nằm trong TargetSegments của bất kỳ ArpDeviceStatus nào）cũng được đưa vào đối tượng bỏ qua tự động xóa tương tự segment do thiết bị Failed phụ trách（xác định ở v1.3）. Việc xác định loại trừ cho mục đích bỏ qua tự động xóa do Worker tự động xóa thực hiện tại thời điểm chạy, áp dụng cho toàn bộ segment không phụ thuộc giá trị IsActive（tính lại tại thời điểm bắt đầu quét. xử lý đầu 7.4）. Mặt khác, đối chiếu coverage ARP dùng cho thông báo（1 lần/ngày）vẫn chỉ áp dụng cho segment có IsActive=true như trước đây（7.2）.（bổ sung v1.4. thay đổi yêu cầu=A-2）

## 3.2 Yêu cầu phi chức năng

- Không phát sinh chi phí license bổ sung. Triển khai trong phạm vi Power Apps for Microsoft 365 / Power Automate for Microsoft 365（chỉ Standard connectors）/ SharePoint / Entra ID có trong Microsoft 365 E5. Tuy nhiên, phí lưu trữ theo mức sử dụng của Azure Backup và phí vận hành Azure VM sẽ phát sinh riêng như chi phí vận hành hệ thống này. Ngoài ra, tùy theo nhu cầu vận hành, có thể xem xét cấp license cho tài khoản dịch vụ dùng chung（1 account）làm owner của Power Apps / Power Automate.

- Mức độ phức tạp phải nằm trong phạm vi có thể vận hành liên tục với đội hình 3 người. Yêu cầu này được loại khỏi đối tượng đánh giá nghiệm thu, và được xem là đáp ứng khi tài liệu quy trình vận hành・quy trình bảo trì master được bên đặt hàng review và phê duyệt（xác định ở v1.3）.

- Tiền đề về quy mô xử lý（bổ sung v1.1）: số lượng đăng ký hằng năm khoảng 200件, số AutoDetected phát hiện mới thường xuyên khoảng 10件/năm（IP không chính quy）. Tuy nhiên, khi vận hành ban đầu, các IP cố định đang được thiết lập thủ công hiện có sẽ được đăng ký hàng loạt dưới dạng AutoDetected（hành vi nhằm lập sổ quản lý cho các IP cố định hiện có）. Với quy mô này, phải mất hơn 10 năm mới đạt ngưỡng 5000 item của SharePoint list, nên thiết kế chia list・archive không thuộc scope ban đầu.

- Mục tiêu là từ lúc đăng ký đến khi hoàn tất đăng ký IPAM・DNS trong vòng 30 phút mà không cần quản trị viên can thiệp. Giá trị mục tiêu này là mục tiêu nỗ lực（SLO）và loại khỏi tiêu chí nghiệm thu. Khi nghiệm thu sẽ báo cáo giá trị đo thực tế tham khảo cho 2 case: đăng ký đơn lẻ và đăng ký hàng loạt 20件（xác định ở v1.3）.

- Có thể truy vết lịch sử của toàn bộ đăng ký và toàn bộ thay đổi theo từng user Entra ID. Các thay đổi do hệ thống（Worker/Power Automate）thực hiện sẽ được ghi dưới tên service account, nhưng yêu cầu này được xem là đáp ứng nếu có thể truy vết gián tiếp về người đăng ký thông qua RequestId và event log（xác định ở v1.3. xem 9.3）.

- Có thể cùng tồn tại với vận hành thiết lập IP thủ công hiện có（không bắt buộc thay đổi thiết lập phía terminal）.

## 3.3 Ngoài phạm vi

- Luồng phê duyệt（xử lý tự động ngay sau khi đăng ký）.

- Chức năng xóa dành cho người dùng（xử lý thủ công thông qua IT Portal）.

- Chỉ định thời gian sử dụng（ngày dự kiến kết thúc）. Tất cả đăng ký được xem là sử dụng lâu dài.

- Thay đổi hostname・chuyển đổi DNS（bộ phận IT xử lý thủ công）.

- Giữ trước IP khi migrate server（bộ phận IT xử lý thủ công）.

- Tạo mới・thay đổi DHCP scope và chuẩn hóa quy tắc đặt tên scope（tuân theo vận hành hiện có）.

- Sử dụng như sổ quản lý thiết bị mạng（DCIM）（hệ thống này chỉ giới hạn cho mục đích IPAM）.

- Liên kết với nền tảng xác thực như 802.1X.

- Hỗ trợ IPv6（mở rộng trong tương lai）.

- Hỗ trợ chuyển đổi đa ngôn ngữ（mở rộng trong tương lai）. Ngôn ngữ UI cơ bản là tiếng Nhật. Các cột tên hiển thị（SegmentName, SiteName, v.v.）được đặt tên với giả định sau này có thể hiển thị song ngữ Nhật-Anh.

- Đăng ký DNS cho hostname CNAME của NKSV（hostname đặc biệt）（xử lý thủ công）.

- Tạo hướng dẫn thiết lập terminal ngoài Windows（tiếp tục vận hành theo cách người dùng tự xử lý）.

# 4. Kiến trúc tổng thể

## 4.1 Thành phần cấu thành

| **Phân loại** | **Component** | **Vai trò** | **Ghi chú** |
|----|----|----|----|
| Cloud（M365） | Power Apps | UI đăng ký dành cho end user | Chuẩn E5 |
| Cloud（M365） | SharePoint list（7 list） | Lưu sổ đăng ký và master data | Chi tiết xem chương 6（bổ sung ArpDeviceStatus） |
| Cloud（M365） | Power Automate | Tiếp nhận đăng ký・thông báo・thông báo MissLog・thông báo liên động NotificationStage | Chỉ sử dụng Standard connectors |
| Cloud（M365） | Entra ID | Xác thực user・cung cấp thuộc tính | Sử dụng tenant hiện có |
| Cloud（Azure） | Azure VM（kiêm IPAM và Worker） | Chạy chung Windows IPAM chính và toàn bộ Worker | 4vCPU/16GB, join AD nội bộ |
| Cloud（Azure） | Azure Backup（MARS） | Backup hằng ngày cho IPAM+Worker server | Recovery Services vault |
| On-premise | Windows DHCP 4 máy | Cấp phát động DHCP（không tạo reservation） | Cấu hình hiện có・cơ chế backup hiện có |
| On-premise | DNS tích hợp AD | Quản lý record DNS | Cấu hình hiện có, ad.nkc.co.jp |
| On-premise | Thiết bị NW（Cisco/Fortinet/Yamaha/Meraki） | Nguồn thu thập ARP | SNMP hoặc API |

## 4.2 Danh sách Worker

| **Tên Worker** | **Ngôn ngữ** | **Tần suất chạy** | **Xử lý chính** |
|----|----|----|----|
| Worker cấp phát IP | PowerShell | Cố định 5 phút（xác định ở v1.3） | Phát hiện case Pending → đăng ký IPAM → đăng ký DNS（khi có hostname）→ cập nhật SharePoint・thu hồi trạng thái Processing bị tồn đọng. Chặn cấp phát đối với segment đang thay đổi range・sửa tổng hợp trạng thái cha ở đầu chu kỳ（bổ sung v1.4） |
| Worker đồng bộ segment | PowerShell | Mỗi 30 phút（bắt đầu lúc phút 15/45 mỗi giờ. xác định ở v1.3） | Đồng bộ thông tin DHCP scope vào danh sách Segments・kiểm tra ngưỡng IP trống・kiểm tra đối chiếu DHCP scope ⇔ Segments・đồng bộ IPAM range・kiểm tra đối chiếu coverage ARP. Phát hiện thay đổi range・quản lý RangeChangePending・ghi kết quả phán định coverage（bổ sung v1.4）【xóa phần ghi chú trong ngoặc: (g)-4】 |
| Worker thu thập ARP | Python＋PowerShell（phần phản ánh IPAM） | 1 giờ（bắt đầu lúc phút 00 mỗi giờ. xác định ở v1.3） | Lấy ARP từ toàn bộ thiết bị NW・đăng ký/cập nhật IPAM・Upsert cập nhật danh sách ArpDeviceStatus |
| Worker tự động xóa | PowerShell | Hằng ngày（ban đêm）（bắt đầu 02:00. xác định ở v1.3） | Xóa theo từng giai đoạn dựa trên LastSeenAt・cập nhật NotificationStage・điều khiển skip bằng cách tham chiếu ArpDeviceStatus. Tính lại điều kiện loại trừ tại thời điểm chạy・ghi SkippedDays・sub-flow hết hạn Cooldown（bổ sung v1.4） |

※ Tần suất chạy Worker đồng bộ segment: sửa “hằng ngày（ban đêm）” ở v1.2 thành “mỗi 30 phút”（phản ánh vấn đề đã biết ở mục 5.3）.

※ Azure VM được thiết lập timezone JST. Script giám sát chạy hằng ngày, bắt đầu lúc 07:00（xác định ở v1.3）.

## 4.3 Phân định trách nhiệm

### Vai trò của Windows IPAM

- Nguồn sự thật của toàn bộ địa chỉ IP. Quản lý tập trung mọi IP, bất kể thông qua đăng ký hay tự động phát hiện.

- Engine tìm kiếm IP trống và phán định cấp phát.

- Liên kết với thông tin DHCP scope（chức năng liên kết IPAM）.

### Vai trò của SharePoint list

Danh sách Segments là nguồn thông tin chính của master segment（bao gồm cả segment không tồn tại DHCP scope）.

IPRequests là sổ tiếp nhận của workflow đăng ký.

ArpDeviceStatus là sổ quản lý trạng thái của thiết bị thu thập ARP.

Nguồn dữ liệu UI của Power Apps（Regions, Segments, OfficeLocationMap）.

Lưu thông tin người đăng ký và metadata của workflow.

Được giữ lại với ý nghĩa là lịch sử đăng ký sau khi đã đăng ký vào IPAM.

## 4.4 Hình ảnh cấu hình logic

\[ End user \] → Power Apps → SharePoint list（M365）

↓↑ (Graph API, HTTPS)

\[ Azure VM: Windows IPAM + nhóm Worker \] ← (VPN/ExpressRoute) → On-premise

├ Windows IPAM（phần chính）

├ Worker cấp phát IP / đồng bộ / tự động xóa（PowerShell）

└ Worker thu thập ARP（Python）（kết quả thu thập được đăng ký vào IPAM thông qua script phản ánh PowerShell）

↓↑

\[On-premise\] 4 máy Windows DHCP / DNS tích hợp AD / thiết bị NW（SNMP/API）

# 5. Thiết kế màn hình（Power Apps）

## 5.1 Danh sách màn hình

Màn hình nhập đăng ký: màn hình chính để nhập đăng ký IP cố định.

Màn hình xác nhận: xác nhận lần cuối nội dung đã nhập và gửi.

Màn hình lịch sử đăng ký: xem các đăng ký trước đây của chính user đang đăng nhập.

Màn hình quản trị（tùy chọn）: quản trị viên xem và can thiệp trên toàn bộ đăng ký. Ở triển khai ban đầu, thay thế bằng view của SharePoint list.

## 5.2 Các mục của màn hình nhập đăng ký

<table>
<colgroup>
<col style="width: 8%" />
<col style="width: 13%" />
<col style="width: 5%" />
<col style="width: 71%" />
<col style="width: 0%" />
</colgroup>
<thead>
<tr>
<th><strong>Mục</strong></th>
<th><strong>Cách nhập</strong></th>
<th><strong>Bắt buộc</strong></th>
<th><strong>Ghi chú・Validation</strong></th>
<th></th>
</tr>
</thead>
<tbody>
<tr>
<td>Khu vực</td>
<td>Dropdown</td>
<td>Bắt buộc</td>
<td colspan="2">Theo đơn vị tỉnh/thành hoặc quốc gia. Ước tính giá trị ban đầu từ OfficeLocationMap. Có thể thay đổi thủ công.</td>
</tr>
<tr>
<td>Cơ sở</td>
<td>Dropdown</td>
<td>Bắt buộc</td>
<td colspan="2">Lọc theo khu vực.</td>
</tr>
<tr>
<td>Segment</td>
<td>Combobox</td>
<td>Bắt buộc</td>
<td colspan="2">Lọc theo cơ sở. Hiển thị kèm CIDR.</td>
</tr>
<tr>
<td>Hostname</td>
<td>Text</td>
<td>Tùy chọn</td>
<td colspan="2">Chỉ validation bằng biểu thức chính quy khi có nhập. Dùng cho đăng ký DNS. Khi không nhập thì bỏ qua đăng ký DNS. Worker kiểm tra trùng lặp.</td>
</tr>
<tr>
<td>Mô tả mục đích sử dụng</td>
<td>Text area</td>
<td>Bắt buộc</td>
<td colspan="2">Thiết bị gì（trong vòng 200 ký tự）</td>
</tr>
</tbody>
</table>

※ Không đưa MAC address vào mục nhập đăng ký. Áp dụng phương thức liên kết sau bằng thu thập ARP tự động.

※ Hỗ trợ cấp phát hàng loạt: hostname và mô tả mục đích sử dụng được nhập theo từng dòng chi tiết（tối đa 20 dòng）. Không triển khai nút tự động sinh số thứ tự hostname（đã xác định ở v1.3. Bản thân chức năng cấp phát hàng loạt vẫn được duy trì, hostname sẽ được nhập thủ công theo từng dòng chi tiết）.

※ Hiển thị banner lưu ý ở phần trên của màn hình nhập đăng ký（ngay phía trên form nhập）. Nội dung hiển thị: “Nếu không nhập hostname, hệ thống sẽ không thực hiện đăng ký DNS. Khi cần đăng ký DNS, hãy nhập theo quy tắc đặt tên（NKSV/NKNODE/PCD/PCM/PCS/PRT + số）.”

※ Bố trí khu vực hướng dẫn ở phần dưới của màn hình nhập đăng ký（phía trên nút gửi）. Nội dung hiển thị（text cố định + link）: (1) Nếu muốn được cấp phát bằng cách chỉ định một địa chỉ IP cụ thể thì đăng ký qua IT Portal. (2) Thay đổi・xóa nội dung đăng ký thì đăng ký qua IT Portal. (3) Thay đổi hostname・chuyển đổi DNS thì đăng ký qua IT Portal. (4) Tư vấn về lỗi đăng ký・hỗ trợ migration thì liên hệ IT Portal. (5) Câu hỏi thường gặp（link tới trang FAQ, URL xác định khi triển khai）. Phương thức triển khai: hiển thị tĩnh bằng Label control + hàm Hyperlink của Power Apps.

## 5.3 Thông tin tự động lấy ở background

UPN người đăng ký（User Principal Name）

Họ tên người đăng ký（tên hiển thị）

Địa chỉ email người đăng ký

Bộ phận trực thuộc（Department）

Cơ sở trực thuộc（OfficeLocation）- sử dụng để ước tính giá trị ban đầu của khu vực・cơ sở

Cấp trên（Manager）- sử dụng trong thông báo liên quan đến xóa

Ngày giờ đăng ký（timestamp）

## 5.4 Triển khai dropdown cascade 3 cấp

Triển khai cascade 3 cấp Khu vực → Cơ sở → Segment bằng các hàm chuẩn của Power Apps và OfficeLocationMap.

Không tạo mới list Sites dành cho master cơ sở（SharePoint list vẫn giữ nguyên 7 list）. Dropdown cơ sở sẽ collection hóa Segments bằng OnStart, Distinct theo SiteCode và hiển thị SiteName. Giới hạn số dòng dữ liệu Segments của Power Apps được nâng lên 2000（tổng số Segments giả định khoảng 1000件）. Thứ tự hiển thị theo SiteName, và sai khác cách ghi SiteName được xem là lưu ý vận hành（xác định ở v1.3）.

**【Ước tính giá trị ban đầu】**

Từ kết quả LookUp(OfficeLocationMap, OfficeLocation = User().OfficeLocation), lấy RegionCode và SiteCode rồi thiết lập làm giá trị ban đầu. Khi không match thì giữ trạng thái chưa chọn（ghi vào OfficeLocationMissLog）.

**【Segment Combobox】**

Items: Filter(Segments, SiteCode = DropdownSite.Selected.SiteCode && IsActive = true && RangeChangePending = false)

Loại trừ các segment có RangeChangePending=true khỏi lựa chọn（hỗ trợ hạn chế phát sinh đăng ký. Hạn chế chính được thực hiện phía Worker＝7.1）.（thay thế v1.4）

Trong template Combobox, hiển thị 2 dòng với Primary Text=SegmentName, Secondary Text=CIDR.

## 5.5 Thông số màn hình xác nhận

Trên màn hình xác nhận, hiển thị nổi bật hostname và segment（kèm CIDR）bằng font lớn（do Worker cấp phát sau khi gửi đăng ký nên tại thời điểm trước khi gửi, IP chưa được xác định. Xóa hiển thị “IP”. xác định ở v1.3）.

Bắt buộc checkbox “Hostname này đã chính xác chưa?”（không check thì không thể gửi）.

Luôn hiển thị thông báo cảnh báo “Việc sửa sau khi đăng ký cần yêu cầu qua IT Portal”.

Khi cấp phát hàng loạt, hiển thị danh sách chi tiết（số lượng・hostname・mục đích sử dụng）trên màn hình xác nhận.

Khi chưa nhập hostname, hiển thị rõ “Không thực hiện đăng ký DNS”.

# 6. Mô hình dữ liệu

## 6.1 Cấu hình

Dữ liệu được lưu giữ bằng 7 SharePoint list và 4 trường tùy chỉnh của Windows IPAM. Trách nhiệm tham chiếu mục 4.3.

7 SharePoint list: Regions, Segments, IPRequests, IPRequestItems, OfficeLocationMap, OfficeLocationMissLog, ArpDeviceStatus

4 trường tùy chỉnh của Windows IPAM: Source（thêm giá trị Cooldown）, RequestId, LastSeenAt, CooldownStartedAt（tạo mới ở v1.3. dùng để lưu điểm bắt đầu Cooldown）

Các cột sau được tạo làm cột index của SharePoint（đối sách query・delegation của Power Apps. thêm v1.1）: IPRequests.Status／RequesterUpn, IPRequestItems.Status／ParentItemId／AssignedIp. Segments.SiteCode／RegionCode cũng là cột index（thêm v1.3. 대응 Q45）.

※ Ở v1.0 đã thêm IPRequestItems và ArpDeviceStatus, vì vậy tổng số SharePoint list là 7 list（“6 list” là lỗi ghi nhầm nên đã sửa）.

## 6.2 Regions（master khu vực）

| **Tên cột**  | **Kiểu**    | **Mô tả**                                 |
|--------------|-------------|-------------------------------------------|
| RegionCode   | Text 1 dòng | Mã khu vực（ví dụ: saitama, gunma, usa）  |
| RegionName   | Text 1 dòng | Tên hiển thị（ví dụ: Saitama, Gunma, Mỹ） |
| DisplayOrder | Số          | Thứ tự hiển thị trong dropdown            |
| IsActive     | Có/Không    | Cờ hiệu lực                               |

## 6.3 Segments（master segment）

Nguồn thông tin chính của master segment. Đăng ký toàn bộ segment bất kể có DHCP scope hay không. Chỉ các record có DhcpScopeExists=true được Worker đồng bộ cập nhật mỗi 30 phút（tuy nhiên UsageCount・CapacityTotal・các mục phát sinh từ coverage có thể thuộc đối tượng cập nhật bất kể giá trị DhcpScopeExists theo từng quy định cập nhật ở 7.2）.（thay thế v1.4）

| **Tên cột** | **Kiểu** | **Mô tả** |
|----|----|----|
| SegmentName | Text 1 dòng | Tên logic（ví dụ: Trung tâm sản xuất Tomioka - segment server） |
| SiteCode | Text 1 dòng | Mã cơ sở（ví dụ: tomioka-seisan） |
| SiteName | Text 1 dòng | Tên hiển thị cơ sở（ví dụ: Trung tâm sản xuất Tomioka） |

※ Việc bổ sung cột vào bảng này dừng lại ở v1.4 với 7 cột bổ sung + 1 cột di chuyển（DnsServers）. Việc hạn chế thông báo lỗi truy vấn DHCP server đại diện（7.2）ở mức 1 lần/ngày sẽ không bổ sung cột vào 6.3 mà lưu giữ cục bộ phía Worker（quy định tại 8.4）.

## 6.4 IPRequests（sổ đăng ký yêu cầu）

| **Tên cột** | **Kiểu** | **Mô tả** |
|----|----|----|
| RequestId | Text 1 dòng | ID duy nhất. Đánh số xác định theo dạng REQ-yyyymmdd-{ID item cha}（không dùng bộ đếm tuần tự nên không xung đột dù đăng ký đồng thời. Ví dụ: REQ-20260421-1052）. Khi cấp phát hàng loạt, liên kết với nhiều record IPRequestItems. |
| RequesterUpn | Text 1 dòng | UPN người đăng ký |
| BatchSize | Số | Số lượng dòng chi tiết đăng ký（1〜20） |
| RequesterName | Text 1 dòng | Họ tên người đăng ký |
| RequesterEmail | Text 1 dòng | Email người đăng ký |
| Department | Text 1 dòng | Bộ phận trực thuộc |

【Lưu ý】HostName/Purpose/AssignedIp/AssignedFqdn đã được chuyển sang list con（IPRequestItems）do hỗ trợ cấp phát hàng loạt. Ngay cả khi đăng ký 1件 cũng tạo 1 dòng chi tiết trong list con.

## 6.5 IPRequestItems（list chi tiết đăng ký）

Lưu giữ chi tiết đăng ký để hỗ trợ cấp phát hàng loạt. Khi đăng ký 1件 cũng tạo 1 dòng chi tiết trong list này. Quản lý giai đoạn thông báo xóa（NotificationStage）được thực hiện theo đơn vị list này（chi tiết）（thay đổi v1.1）.

| **Tên cột** | **Kiểu** | **Mô tả** |
|----|----|----|
|  |  | Cột đã bị bãi bỏ（xác định ở v1.3）. Lấy SharePoint item ID làm khóa duy nhất chính thức. |
| ParentItemId | Số | SharePoint item ID của IPRequests cha（khóa tham chiếu）. RequestId dùng để hiển thị được tham chiếu từ record cha. |
| HostName | Text 1 dòng | Hostname（tùy chọn, khi không nhập thì null） |
| Purpose | Text nhiều dòng | Mô tả mục đích sử dụng |
| Status | Choice | Pending/Processing/Assigned/Failed/Archived（thêm ở v1.1: thiết lập khi xóa sau 12 tháng） |
| RetryCount | Số | Số lần retry theo từng dòng chi tiết. Gộp số lần xử lý lại qua chu kỳ do lỗi tạm thời trong process và số lần cộng do thu hồi Processing bị tồn đọng（7.1）vào cùng một counter; bất kể đường xử lý nào, kết thúc khi đạt giới hạn 3 lần.（thêm v1.4） |
| NotificationStage | Choice | Quản lý giai đoạn thông báo xóa（đã chuyển từ IPRequests ở v1.1）. Giá trị: None / 3M-Reminder / 6M-Reminder / 12M-Deleted / Error. Power Automate gửi thông báo tổng hợp khi cột này thay đổi. Khi chuyển giai đoạn, chỉ với các chi tiết chưa thiết lập NotificationSentAt thì clear trong cùng lần cập nhật（duy trì trạng thái chưa thiết lập）. Chỉ khi ghi đè phục hồi từ trạng thái Error thì giữ SentAt của chi tiết đã gửi（quy tắc chi tiết và idempotent touch/re-drive lấy 7.4 làm chuẩn）.（thay thế v1.4） |
| NotificationSentAt | Ngày giờ | Quản lý trạng thái đã gửi của thông báo tổng hợp（tạo mới ở v1.1）. Power Automate cập nhật sau khi gửi hoàn tất. Chỉ chi tiết chưa thiết lập mới là đối tượng tổng hợp. Cập nhật sau khi xác nhận gửi thành công（quy ước chung của notification flow ở 7.4）.（thêm v1.4） |
| AssignedIp | Text 1 dòng | IP đã được cấp phát（Worker ghi） |
| AssignedFqdn | Text 1 dòng | FQDN đã đăng ký（chỉ khi có hostname） |
| ProcessedAt | Ngày giờ | Ngày giờ hoàn tất xử lý |
| FailureNotifiedAt | Ngày giờ | Quản lý đã gửi thông báo thất bại（#3）（tạo mới ở v1.3）. Chỉ gửi khi chưa thiết lập và cập nhật sau khi gửi（cùng pattern với NotificationSentAt）. Độ song song của flow là 1 và tuân theo quy ước chung của notification flow ở 7.4.（thêm v1.4） |
| ErrorCategory | Choice | Phân loại nguyên nhân thất bại. Giá trị: DnsDuplicate/NoFreeIp/NamingRule/SystemError/DnsDuplicateDynamic（do record đăng ký động）. Worker thiết lập và dùng để chọn message của Power Automate（tạo mới ở v1.3）. Danh sách trigger thiết lập lấy ghi chú tổng hợp ở 7.1 làm chuẩn. Khi Failed được xác định bởi tuyến bảo vệ phía UI thì Power Apps thiết lập.（thêm v1.4） |
| ErrorMessage | Text nhiều dòng | Thông báo lỗi khi thất bại |

## 6.6 OfficeLocationMap（master chuyển đổi OfficeLocation）

| **Tên cột** | **Kiểu** | **Mô tả** |
|----|----|----|
| OfficeLocation | Text 1 dòng | Giá trị OfficeLocation của Entra ID（khóa match） |
| RegionCode | Text 1 dòng | Mã khu vực tương ứng |
| SiteCode | Text 1 dòng | Mã cơ sở tương ứng |
| IsActive | Có/Không | Cờ hiệu lực |
| Note | Text 1 dòng | Ghi chú（cách ghi cũ・nguồn tích hợp, v.v.） |

## 6.7 OfficeLocationMissLog（log không khớp）

| **Tên cột** | **Kiểu** | **Mô tả** |
|----|----|----|
| DetectedAt | Ngày giờ | Ngày giờ phát hiện |
| OfficeLocation | Text 1 dòng | Giá trị OfficeLocation không match |
| RequesterUpn | Text 1 dòng | UPN người đăng ký |
| Resolved | Có/Không | Cờ đã xử lý（team network/infrastructure cập nhật） |

※ Cột BatchSize đã bị xóa vì MissLog là 1 đăng ký = 1 record nên không cần thiết（対応 I-6）.

## 6.8 Trường tùy chỉnh Windows IPAM

| **Tên field** | **Kiểu** | **Mục đích sử dụng** |
|----|----|----|
| Source | Multi-value | Requested/AutoDetected/Cooldown. Dùng để phán định policy tự động xóa và có cần đăng ký DNS hay không. Cooldown dùng để giữ IP trong thời gian cooldown. Khi chuyển sang Cooldown thì gán thêm vào giá trị Source gốc（multi-value）. Khi gán giá trị Cooldown, đồng thời thiết lập CooldownStartedAt（tham chiếu bảng này）.（thêm v1.4） |
| RequestId | Free form | Khóa liên kết với sổ đăng ký SharePoint. Với AutoDetected thì để trống（đối với cấp phát theo đơn vị chi tiết, lưu “REQ-yyyymmdd-{ID item cha}-{ID item chi tiết}”. IPRequests.RequestId phía SharePoint vẫn giữ cách đánh số theo đơn vị cha, không thay đổi. thay đổi v1.2）. Worker tự động xóa（7.4）trích xuất ID item chi tiết từ giá trị này và reverse lookup IPRequestItems（tham chiếu quy định xác định chi tiết ở 7.4）.（thêm v1.4） |
| LastSeenAt | Free form | Ngày giờ phản hồi ARP gần nhất（định dạng ISO 8601）. Lưu theo ISO 8601 kèm offset JST（ví dụ: 2026-07-03T14:00:00+09:00）. Phán định xóa tính số ngày theo chênh lệch ngày sau khi chuyển sang JST（xác định ở v1.3）. Khi cấp phát thành công thì khởi tạo bằng ngày giờ cấp phát（định nghĩa điểm bắt đầu của IP chưa phản hồi. v1.1）. Dùng cho phán định tự động xóa. |
| CooldownStartedAt | Free form | Ngày giờ chuyển sang Cooldown（điểm bắt đầu tính）. Lưu theo ISO 8601 kèm offset JST（ví dụ: 2026-07-03T02:15:00+09:00）. Thiết lập trong cùng lần cập nhật với việc gán thêm giá trị Cooldown vào Source. Dùng làm điểm bắt đầu phán định xóa vật lý khi hết Cooldown（công thức phán định và chủ thể thực hiện tham chiếu sub-flow hết hạn Cooldown ở 7.4）. Khi khôi phục（cả tự động khôi phục và IT manual restore）phải luôn clear. Tạo mới ở v1.4. |

※ Quy ước tính số ngày đã trôi qua（áp dụng chung cho mọi phán định xóa）: số ngày trôi qua từ LastSeenAt・CooldownStartedAt được tính bằng chênh lệch ngày sau khi chuyển sang JST. Điều kiện ngưỡng là “số ngày đã trôi qua ≥ ngưỡng”（bao gồm ngày đạt ngưỡng）. Khi tính số ngày đã trôi qua, trừ SkippedDays（6.3）của segment tương ứng khỏi chênh lệch ngày（thời gian bị đóng băng không tiêu thụ thời gian gia hạn. Áp dụng chung cho AutoDetected 30 ngày・Requested 90/180/365 ngày・hết hạn Cooldown. thay đổi yêu cầu=A-1. Định nghĩa hiệu chỉnh lấy mục này（6.8-2）làm chuẩn）.（thêm v1.4・bổ sung v1.4）

## 6.9 ArpDeviceStatus（list trạng thái thiết bị thu thập ARP）

List quản lý trạng thái thiết bị thu thập ARP（tạo mới ở v1.0）. Worker thu thập ARP cập nhật Upsert theo từng lần xử lý thiết bị.

List này đồng thời đóng vai trò master của thiết bị thuộc đối tượng thu thập ARP, và Worker lấy thiết bị mục tiêu từ list này（việc thêm・loại bỏ dòng thiết bị・thay đổi TargetSegments do team network/infrastructure thực hiện. Tham chiếu 10.6. bổ sung v1.1）.

Gateway dự phòng như VRRP/HSRP chỉ đăng ký 1 máy đại diện, không đăng ký máy standby. Khi máy đại diện lỗi, cho phép dừng phát hiện ARP（bảo toàn bằng phát hiện lỗi liên tục 72 giờ → skip tự động xóa segment tương ứng. xác định ở v1.1）.

| **Tên cột** | **Kiểu・Mô tả** |
|----|----|
| DeviceId | Text 1 dòng. ID duy nhất của thiết bị（ví dụ: cisco-cat-tomioka-01） |
| DeviceName | Text 1 dòng. Tên thiết bị（dùng để hiển thị） |
| DeviceFqdn | Text 1 dòng. FQDN（đích kết nối khi thu thập ARP） |
| DeviceType | Choice. Dùng để phân biệt phương thức thu thập・vendor（CiscoIOS/FortiGate/YamahaRTX/MerakiMX）. Tạo mới ở v1.3. Đây là key điều khiển nhánh phương thức thu thập của Worker thu thập ARP（7.3）. Thiết bị chưa thiết lập hoặc có giá trị ngoài định nghĩa sẽ bị skip thu thập và được tính là thất bại（7.3）. Khi thêm dòng thiết bị, bắt buộc nhập giá trị ban đầu（10.6・Phụ lục C.6）.（thêm v1.4） |
| MerakiOrgId | Text 1 dòng. Meraki organization ID. Đây là mục ghi nhận để tham chiếu sổ quản lý・vận hành, không được tham chiếu trong xử lý thu thập ở 7.3（thu thập chỉ dùng MerakiNetworkId）.（làm rõ mục đích ở v1.4） |
| MerakiNetworkId | Text 1 dòng. Meraki network ID（chỉ dùng cho thiết bị Meraki, đăng ký theo nguyên tắc 1 thiết bị = 1 network）. Tạo mới ở v1.3. Trong thu thập Meraki ở 7.3, dùng để gọi /networks/{MerakiNetworkId}/clients.（thêm v1.4） |
| TargetSegments | Text nhiều giá trị. Danh sách CIDR mà thiết bị này phụ trách（phương thức forward lookup） |
| LastSuccessAt | Ngày giờ. Thời điểm thu thập ARP thành công gần nhất |
| LastAttemptAt | Ngày giờ. Thời điểm thử thu thập ARP gần nhất |
| ConsecutiveFailureCount | Số. Số lần thất bại liên tiếp（reset về 0 khi thành công） |
| CurrentStatus | Choice. OK / Failed |
| LastErrorMessage | Text nhiều dòng. Chi tiết lỗi gần nhất |
| LastNotifiedAt | Ngày giờ. Dùng để ngăn thông báo trùng（ngày giờ thông báo cuối cùng） |

# 7. Luồng xử lý

## 7.1 Luồng tiếp nhận đăng ký〜cấp phát

Người dùng truy cập Power Apps và hoàn tất xác thực Entra ID.

Nhập và gửi form đăng ký. Power Apps tạo record mới trong list IPRequests（Status=Pending）. Lấy ID item cha từ giá trị trả về của Patch, rồi tạo các dòng chi tiết trong IPRequestItems（ParentItemId=ID item cha, Status=Pending, NotificationStage=None, NotificationSentAt=trống khi khởi tạo）. FailureNotifiedAt cũng được tạo ở trạng thái trống（chưa thiết lập）. Khi tạo IPRequests cha, CompletionNotifiedAt cũng để trống（chưa thiết lập = chưa gửi, dùng để phán định đã gửi trong từng notification flow）.（thêm v1.4）

Power Automate thiết lập RequestId（đánh số xác định theo REQ-yyyymmdd-{ID item cha}）và gửi email tiếp nhận đăng ký. Để tránh việc chậm đánh số làm chặn cấp phát, Worker cũng có thể suy ra RequestId bằng cùng công thức. Ngày giờ chuẩn của yyyymmdd được thống nhất theo Created của record cha（ngày sau khi chuyển đổi sang JST）. Vì giá trị Power Automate thiết lập và giá trị Worker suy ra đều được tính từ cùng đầu vào nên theo định nghĩa sẽ không phát sinh sai khác（nếu phát sinh thì xem là bug. xác định ở v1.3）.

Nếu không match trong OfficeLocationMap, thêm record vào list MissLog（thông báo ngay thông qua flow riêng）. Việc thêm record vào MissLog do flow tiếp nhận đăng ký（Power Automate, nguồn trigger của Phụ lục F#8）thực hiện（phía Power Apps chỉ phát hiện）.（thêm v1.4）

Ở đầu mỗi chu kỳ, trước khi lấy các dòng chi tiết Pending, Worker tìm các record cha có Status=Pending và toàn bộ số dòng chi tiết tương ứng BatchSize đã đạt trạng thái kết thúc（Assigned/Failed）, rồi thực hiện cập nhật tổng hợp Status của record cha（tự phục hồi trong trường hợp xử lý bị gián đoạn sau khi ghi trạng thái kết thúc cho dòng chi tiết cuối cùng nhưng trước khi tổng hợp cha, ví dụ do crash. Đây là thao tác idempotent chỉ ghi giá trị đúng theo quy tắc tổng hợp và tuân theo quy định PATCH tương ứng）.（bước mới ở v1.4）

Worker cấp phát IP giám sát SharePoint mỗi 5 phút（xác định ở v1.3, nhất quán với 4.2）, lấy các dòng chi tiết có IPRequestItems.Status=Pending（join với record cha bằng ParentItemId）. Xử lý theo hướng điều khiển bởi dòng chi tiết, Status của record cha được cập nhật như kết quả tổng hợp của các dòng chi tiết.

Trong các dòng chi tiết đã lấy, những dòng thuộc segment có RangeChangePending=true sẽ được giữ nguyên Pending và skip xử lý trong chu kỳ hiện tại（không cộng RetryCount, cũng không đưa vào đối tượng thu hồi Processing bị tồn đọng〔30 phút〕）. Tình trạng tồn đọng trong thời gian đang bị hạn chế sẽ được phát hiện bởi thông báo tồn đọng RangeChangePending（7.2）. Việc hạn chế luồng đăng ký phía UI（5.4）được xem là hỗ trợ bổ sung.（bước mới ở v1.4）

Worker cập nhật Status của dòng chi tiết thành Processing（lock）. Để ngăn Worker khởi động nhiều instance, phải triển khai cơ chế mutex hoặc lock file.

Dòng chi tiết vẫn ở Processing quá 30 phút kể từ lần cập nhật cuối được xem là tồn đọng, sẽ được trả về Pending và gửi cảnh báo tới nkis-network（thu hồi khi Worker crash. thêm v1.1）.

- Khi trả về Pending, increment RetryCount của dòng chi tiết đó（số lần cộng được gộp vào cùng RetryCount với retry lỗi tạm thời trong process; bất kể đường cộng nào, kết thúc khi đạt giới hạn 3 lần）. Dòng chi tiết tồn đọng đạt RetryCount≧3 sẽ không trả về Pending mà xác định Status=Failed. Khi xác định Failed, tìm IPAM bằng khóa đơn vị dòng chi tiết（REQ-yyyymmdd-{ID item cha}-{ID item chi tiết}）, nếu tồn tại entry đã đăng ký thì thực hiện rollback IPAM（bao gồm xóa record DNS nếu đã đăng ký DNS）rồi mới xác định Failed（nếu rollback thất bại thì gửi alert khẩn cấp tới nkis-network〔đường hiện có〕）. Đồng thời thiết lập ErrorCategory=SystemError, và thông báo thất bại qua FailureNotifiedAt（Phụ lục F#3）sẽ phát hỏa theo đường hiện có.（thêm v1.4）

Worker thực hiện xử lý phân nhánh theo việc có hay không có hostname（loop theo từng dòng chi tiết, tối đa 20件）.

Worker kiểm tra lại quy tắc đặt tên hostname khi bắt đầu xử lý（kiểm tra phòng thủ cho các đường ngoài Power Apps như chỉnh sửa trực tiếp SharePoint. Nếu vi phạm, thiết lập Status của dòng chi tiết = Failed và thông báo bằng nội dung lỗi quy tắc đặt tên. được khôi phục ở v1.1）.

Retry có cấu hình 2 tầng. (1) Lỗi tạm thời（Graph API, v.v.）được retry tối đa 3 lần trong process bằng exponential backoff（không tăng RetryCount）. (2) Khi xử lý lại qua chu kỳ, increment RetryCount của dòng chi tiết; khi RetryCount≧3 thì xác định Status dòng chi tiết = Failed và gửi thông báo escalation tới nkis-network. Khi thất bại, thực hiện rollback IPAM → đặt Status dòng chi tiết = Pending → xử lý lại ở chu kỳ tiếp theo. Nếu rollback IPAM thất bại thì gửi alert khẩn cấp tới nkis-network.

Khi thành công, đồng thời với đăng ký IPAM, khởi tạo LastSeenAt=ngày giờ cấp phát, rồi ghi IPRequestItems.Status=Assigned, AssignedIp, AssignedFqdn（chỉ khi có hostname）, ProcessedAt vào SharePoint. Trong nội dung email thông báo hoàn tất cấp phát, ghi rõ “hãy đổi thiết lập thủ công sang IP mới đã được thông báo”（hướng dẫn vận hành khi trùng AutoDetected）.

Việc cập nhật tổng hợp IPRequests.Status của record cha chỉ thực hiện khi toàn bộ dòng chi tiết đã đạt trạng thái kết thúc（Assigned hoặc Failed）（toàn bộ Assigned=Assigned／lẫn lộn=PartiallyFailed／toàn bộ Failed=Failed）. Trong khi còn dù chỉ 1 dòng chi tiết Pending hoặc Processing, không cập nhật Status cha và giữ Pending（ngăn phát hỏa nhầm hoặc phát hỏa trùng thông báo hoàn tất cho đăng ký còn dòng đang retry）. Sau khi đã thiết lập giá trị kết thúc, Status cha không chuyển tiếp lần nữa ngoại trừ chuyển sang Archived.

- Cập nhật tổng hợp Status của IPRequests cha được ghi trong cùng PATCH với ProcessedAt・ErrorMessage（giảm số lần trigger Power Automate phát hỏa. Tuy nhiên, việc ngăn phát hỏa nhiều lần tự thân dựa vào độ song song 1 của notification flow + cột guard, không khép kín chỉ bằng việc gộp cùng PATCH — tham chiếu quy ước chung notification flow ở 7.4）. Việc ghi trạng thái kết thúc ở phía dòng chi tiết như Status・AssignedIp・AssignedFqdn・ProcessedAt cũng được gom trong cùng PATCH theo từng dòng chi tiết. Ngoại lệ: khi xác định Failed do thất bại một phần khi tạo dòng chi tiết sau khi tạo cha（tuyến bảo vệ phía UI）, Power Apps ghi đồng thời Status=Failed và ErrorMessage（phù hợp quy định hai lớp bảo vệ của v1.3）. ProcessedAt・ErrorMessage・CompletionNotifiedAt của cha được Power Apps khởi tạo null（chưa thiết lập）khi tạo cha.（thêm v1.4）

Power Automate lấy thay đổi IPRequests.Status của record cha làm trigger để gửi thông báo hoàn tất cho người đăng ký. Nội dung thông báo bao gồm IP, subnet mask, gateway, DNS server（khi có hostname thì bao gồm cả FQDN）.

- Phán định và cập nhật đã gửi của thông báo hoàn tất（Phụ lục F#2）・thông báo thất bại（Phụ lục F#3）（CompletionNotifiedAt/FailureNotifiedAt）tuân theo mô tả ở Phụ lục F#2/#3（phù hợp quy ước chung notification flow ở 7.4）. Thông tin segment ghi trong thông báo hoàn tất（Gateway/SubnetMask/DnsServers）được Power Automate lấy bằng cách Lookup Segments theo IPRequests.SegmentId của record cha（không dùng phương thức Worker copy sang）. Quyền đọc Segments của Power Automate theo mô tả ở 9.1. Nếu thông báo bị thiếu do notification flow thất bại cuối cùng, script giám sát（10.4）sẽ phát hiện hằng ngày trường hợp “CompletionNotifiedAt chưa thiết lập và Status cha đã kết thúc”, rồi khôi phục bằng gửi lại thủ công（không tự động gửi lại）.（thêm v1.4）

（1） Không thực hiện tái kiểm tra trước giữa bước chọn IP trống và đăng ký; xem lỗi uniqueness của Add-IpamAddress là phát hiện trùng（chính thao tác đăng ký là điểm kiểm tra, loại bỏ cửa sổ race của check-then-act）. Khi lỗi, chọn lại bằng IP ứng viên tiếp theo trong cùng chu kỳ（tối đa 3 ứng viên）.

（2） Ở đầu xử lý dòng chi tiết, tìm IPAM bằng khóa đơn vị dòng chi tiết; nếu tồn tại entry đã đăng ký thì không cấp phát mới, mà dùng IP đó để resume xử lý từ đăng ký DNS・ghi SharePoint. Nếu A record hit trong kiểm tra trùng DNS có IP trùng với IP đã đăng ký của chính dòng chi tiết thì xem là phần sót lại của chính mình và tiếp tục xử lý; chỉ khi không khớp mới xác định là trùng và Failed.（thêm v1.2. Trong bảng quan điểm test tích hợp cần xác nhận thực tế lỗi đăng ký trùng của Add-IpamAddress）

（3） Nếu cả 3 ứng viên đều lỗi trùng, cộng RetryCount của dòng chi tiết và trả Status=Pending（retry ở chu kỳ tiếp theo. Khi vượt giới hạn 3 lần thì hợp nhất vào đường hiện có xác định Failed）. Thứ tự chọn ứng viên theo thứ tự ghi trong StaticIpRangeRaw・tăng dần trong range（xác định ở v1.3）.

（4） Các lỗi xác định Failed ngay là không còn IP trống・trùng DNS・vi phạm quy tắc đặt tên（lỗi vĩnh viễn）. Đối tượng retry là lỗi communication/sự cố của Graph・IPAM・DNS（lỗi tạm thời）（xác định ở v1.3）.

※ Thời điểm thiết lập ErrorCategory（danh sách）: NoFreeIp＝khi xác định Failed do cạn kiệt 3 ứng viên IP trống／DnsDuplicate＝khi phát hiện trùng DNS（record tĩnh）／DnsDuplicateDynamic＝khi phát hiện trùng DNS（record đăng ký động）／NamingRule＝khi vi phạm tái kiểm tra hostname／SystemError＝khi xác định Failed do đạt giới hạn RetryCount trong các loại lỗi sự cố khác（bao gồm đường thu hồi tồn đọng）. Mỗi giá trị được Worker thiết lập khi xác định Failed cho dòng chi tiết（Failed do tuyến bảo vệ phía UI thì Power Apps thiết lập）, và được dùng để chọn nội dung message của Phụ lục F#3（8.5）.（tạo mới v1.4）

（5） Nếu việc tạo dòng chi tiết sau khi tạo cha bị thất bại một phần, phía Power Apps hiển thị lỗi khi Patch dòng chi tiết thất bại và đặt record cha Status=Failed（hướng dẫn đăng ký lại）. Phía Worker nếu phát hiện BatchSize không khớp với số lượng dòng chi tiết thực tế thì tạm dừng xử lý đăng ký đó và thông báo tới nkis-network（xác định ở v1.3）.

（6） Trùng hostname giữa các dòng chi tiết trong cùng một đăng ký được loại bỏ bằng validation khi gửi Power Apps（trước khi chuyển sang màn hình xác nhận）（xác định ở v1.3）.

（7） Kiểm tra trùng DNS: nếu query A của Resolve-DnsName có phản hồi（bao gồm resolve CNAME）thì xử lý là trùng（Failed）. Nếu xác định record hiện có có aging timestamp（đăng ký động）thì đặt ErrorCategory=DnsDuplicateDynamic và hướng dẫn bằng message chuyên dụng（dẫn hướng việc cố định hóa/thay thế terminal hiện có sang IT Portal）. Không tự động xóa hoặc ghi đè record động（xác định ở v1.3）.

## 7.2 Luồng đồng bộ master segment（mỗi 30 phút）

Worker đồng bộ chỉ query 2 máy chủ đại diện（nkdc1, nkdc4）và lấy Get-DhcpServerv4Scope, Get-DhcpServerv4ExclusionRange. ScopeId giống nhau trên partner server（nkdc2/nkdc5）không thuộc đối tượng xử lý（thay đổi v1.2. Chi tiết cấu hình failover xem 2.2）.

- Nếu query tới máy chủ đại diện thất bại, chỉ skip đồng bộ các scope thuộc máy chủ đó（list Segments và IPAM range giữ giá trị đồng bộ lần trước＝2.2）, còn đồng bộ scope thuộc máy chủ khác・cập nhật các mục nguồn IPAM・kiểm tra đối chiếu・đối chiếu coverage vẫn tiếp tục（cô lập sự cố theo đơn vị server）. Thông báo lỗi query được hạn chế tối đa 1 lần/ngày cho cùng một server（cho phép lưu trạng thái hạn chế thông báo cục bộ phía Worker. xem 8.4）.（thêm v1.4）

Tính dải IP cố định là “host range của CIDR segment −（scope range − exclusion range）− IP reserved（network/broadcast/Gateway）”. Scope range − exclusion range là dynamic pool do DHCP phân phối động, còn dải IP cố định là tập bù của nó（hỗ trợ cả vận hành định nghĩa scope cho toàn bộ subnet rồi đảm bảo vùng cố định bằng exclusion range, và vận hành chỉ định nghĩa scope cho phần dynamic pool）.

Đồng bộ dải IP cố định đã tính vào IP range của Windows IPAM（segment chưa tạo thì tạo mới bằng Add-IpamRange, khi thay đổi exclusion range thì cập nhật bằng Set-IpamRange. thêm v1.1）. Find-IpamFreeAddress tìm IP trống với range này làm tập mẹ.

Dùng Get-IpamAddress để tổng hợp số IP đang sử dụng trong dải IP cố định（UsageCount）（thực hiện theo thứ tự lấy DHCP → tính exclusion range → query IPAM）.

Kiểm tra số IP trống của từng segment（CapacityTotal − UsageCount）có còn từ 20件 trở xuống hay không（chỉ áp dụng cho toàn bộ segment IsActive=true, không phụ thuộc DhcpScopeExists. sửa v1.2: đọc lại “toàn bộ segment” ở 3.1）. Nếu còn từ 20件 trở xuống và AlertLastNotifiedAt đã trước đó từ 24 giờ trở lên, gửi email alert tới nkis-network@nkc.co.jp và cập nhật AlertLastNotifiedAt. Khi số IP trống phục hồi lên từ 21件 trở lên thì clear AlertLastNotifiedAt.

Thực hiện cập nhật sai khác đối với các record có DhcpScopeExists=true trong list Segments（StaticIpRangeStart/End/Raw, Gateway, SubnetMask, UsageCount, CapacityTotal, DnsServers, LastSyncedAt）. Các record DhcpScopeExists=false duy trì giá trị thủ công.

- Bao gồm DnsServers trong các mục cập nhật sai khác. Với segment DhcpScopeExists=true, lấy Get-DhcpServerv4OptionValue（option 006＝DNS server）từ DHCP server đại diện và ghi vào DnsServers（xem 8.3）. DhcpScopeExists=false duy trì giá trị thủ công.（thêm v1.4）

Thực hiện kiểm tra đối chiếu DHCP scope ⇔ list Segments, khi phát hiện thiếu sót thì thông báo tới nkis-network.

- Đối chiếu dùng subnet của ScopeId và Segments.CIDR làm key（key đối chiếu của 3 pattern phát hiện〔xác định ở v1.3〕）. DhcpScopeName là mục hiển thị/ghi nhận mà Worker đồng bộ lấy tên scope bằng Get-DhcpServerv4Scope rồi ghi vào record DhcpScopeExists=true（người đọc là UI・thông báo・người vận hành）, không dùng làm key đối chiếu（vì tên scope do con người đặt và có thể thay đổi）.（thêm v1.4）

Thực hiện kiểm tra đối chiếu coverage ARP（CIDR của toàn bộ Segments có IsActive=true phải nằm trong TargetSegments của một ArpDeviceStatus nào đó）. Khi phát hiện thiếu sót thì thông báo tới nkis-network（cùng một nội dung tối đa 1 lần/ngày. thêm v1.1）.

- Đồng thời, ghi kết quả đối chiếu của từng segment IsActive=true vào Segments.CoverageStatus（Covered/Uncovered）và cập nhật CoverageCheckedAt. Việc hạn chế thông báo 1 lần/ngày được quản lý bằng CoverageNotifiedAt, và clear khi phục hồi về Covered. Các mục nguồn coverage（CoverageStatus/CoverageCheckedAt/CoverageNotifiedAt）được Worker cập nhật cho toàn bộ segment IsActive=true（không thuộc đối tượng “duy trì giá trị thủ công”, cùng kiểu với quy định v1.3 của các mục nguồn IPAM như UsageCount）. Các cột này dùng cho hạn chế thông báo・hiển thị vận hành・audit, và không được Worker tự động xóa（7.4）tham chiếu trong phán định loại trừ（7.4 tính lại tại runtime）.（thêm v1.4）

Scope đã bị xóa thì thiết lập record tương ứng thành IsActive=false（bản thân record vẫn giữ lại như lịch sử）.

Khi dải IP cố định bị thu hẹp hoặc biến mất do thay đổi exclusion range, không xóa IPAM range mà phản ánh việc thu hẹp bằng Set-IpamRange. Các IP đã cấp phát bị nằm ngoài phạm vi sẽ không tự động xóa, mà thông báo tới nkis-network để phán định thủ công（xác định ở v1.3）.

- Việc bảo vệ không xóa đối với IP đã cấp phát nhưng bị nằm ngoài phạm vi được thực hiện theo predicate theo đơn vị IP ở 7.4（entry không thuộc bất kỳ IPAM range nào thì không thuộc đối tượng phán định xóa, trừ entry Cooldown）. Đây là quy định thường trực, tiếp tục bảo vệ ngay cả sau khi gỡ cờ theo đơn vị segment.（bổ sung v1.4）

  Khi dải IP cố định được mở rộng, việc đưa RangeChangePending về false lấy điều kiện là “LastSuccessAt của toàn bộ thiết bị ArpDeviceStatus phụ trách segment đó mới hơn LastSyncedAt（thời điểm cập nhật range）của segment đó”（xem như xấp xỉ việc ARP ledger hóa phần range mở rộng đã chạy đủ một vòng）. Khi thiết bị phụ trách đang Failed thì sẽ không chuyển về false, nhưng đây là hành vi thiên về an toàn và nhất quán với cơ chế bảo vệ skip xóa do thiết bị Failed.

  Safety net: khi Worker đồng bộ thực hiện thay đổi phạm vi bằng Set-IpamRange, nếu RangeChangePending của segment đó chưa được thiết lập（false）thì tự động thiết lập true và gửi thông báo lệch quy trình tới nkis-network（việc bật cờ trước bằng thao tác thủ công là luồng chính, và vẫn còn cửa sổ tối đa 30 phút trước khi phát hiện — nêu rõ ở 10.3）.（bổ sung v1.4）

UsageCount・CapacityTotal（các mục có nguồn từ IPAM）được Worker cập nhật cho toàn bộ segment không phụ thuộc DhcpScopeExists. Đối tượng “duy trì giá trị thủ công” chỉ giới hạn ở các mục có nguồn từ DHCP（range・Gateway, v.v.）（xác định ở v1.3. Phù hợp với mục đích áp dụng cho toàn bộ segment của Phụ lục D-18）.

- Dải IP cố định của segment DhcpScopeExists=false được xem là toàn bộ CIDR（trừ IP reserved như network/broadcast/Gateway）, và CapacityTotal được Worker tính từ CIDR（phù hợp với quy định nhất quán ở phần mở đầu 7.3 và 3.1）.（bổ sung v1.4）

【Quy ước thực thi xử lý đồng bộ】Xử lý đồng bộ được thực hiện liên tục theo đơn vị segment theo thứ tự “phát hiện thay đổi phạm vi → thiết lập RangeChangePending=true（nếu chưa thiết lập）→ cập nhật range bằng Set-IpamRange → cập nhật sai khác Segments（bao gồm StaticIpRangeRaw）”（thiết lập cờ trước khi cập nhật range）. Không áp dụng phương thức thực hiện theo phase cho toàn bộ segment（cập nhật range cho toàn bộ segment rồi mới cập nhật sai khác hàng loạt）. Ngay cả khi bị gián đoạn và còn lại trạng thái trung gian như “IPAM range=mới／StaticIpRangeRaw=cũ”, lần chạy tiếp theo（sau 30 phút）sẽ tự phục hồi bằng cách tính lại toàn bộ theo phương thức cập nhật sai khác（idempotent）.（tạo mới v1.4）

Mỗi lần chạy, Worker đồng bộ đánh giá điều kiện gỡ đối với các segment có RangeChangePending=true, và đưa RangeChangePending của các segment đạt điều kiện về false. Điều kiện gỡ là: mở rộng＝predicate gỡ ở 7.2 đạt điều kiện（LastSuccessAt của toàn bộ thiết bị ArpDeviceStatus phụ trách segment đó mới hơn LastSyncedAt）, thu hẹp・thay thế＝đã hoàn tất phản ánh thay đổi phạm vi vào Segments（cập nhật sai khác StaticIpRangeRaw）. Cũng cho phép gỡ bằng xác nhận thủ công（10.3）. Người ghi true→false là bước này（và thao tác thủ công）, qua đó xác định đường gỡ cho hạn chế cấp phát（7.1）・giữ đăng ký（7.3）・thông báo tồn đọng（7.2）.（tạo mới v1.4）

Nếu RangeChangePending=true tiếp tục quá 24 giờ（tham số có tiền đề điều chỉnh theo đo thực tế）, Worker đồng bộ gửi thông báo tồn đọng tới nkis-network（hạn chế 1 lần/ngày）. “Thời điểm chuyển true” dùng để phán định tiếp tục 24 giờ dựa trên bản ghi phát hiện cục bộ của Worker（cho phép lưu giữ theo 8.4）.（tạo mới v1.4・bổ sung v1.4）

※ Việc cập nhật UsageCount có thể phát sinh độ trễ tối đa 30 phút（điều được chấp nhận）.

## 7.3 Luồng thu thập ARP・đăng ký tự động（mỗi 1 giờ）

Phán định dải IP cố định của Worker thu thập ARP được thực hiện dựa trên list Segments lấy tại đầu chu kỳ. Segment có DhcpScopeExists=true dùng StaticIpRangeRaw（bản chính）, segment false dùng toàn bộ CIDR để phán định, và không query trực tiếp tới DHCP server. Chấp nhận độ trễ dữ liệu tối đa 30 phút（chu kỳ Worker đồng bộ segment）. Vì tham chiếu cùng nguồn đồng bộ với Worker cấp phát（IPAM range）, ở trạng thái ổn định sau khi phản ánh xong thay đổi phạm vi, phán định phạm vi giữa các Worker sẽ không sai khác. Tuy nhiên, trong quá trình đang phản ánh thay đổi phạm vi（thay đổi DHCP là tức thời, phản ánh IPAM/Segments tối đa 30 phút, ARP ledger hóa khi mở rộng có thể thêm vài giờ）, có thể phát sinh sai khác, vì vậy với segment đang thay đổi phạm vi（RangeChangePending=true）sẽ áp dụng hạn chế cấp phát（7.1/7.2）và giữ đăng ký mới（luồng này）. Các mục lấy trong snapshot Segments ở đầu chu kỳ bao gồm RangeChangePending.（thay thế v1.4）

Worker thu thập ARP dùng script Python để lấy thiết bị mục tiêu từ list ArpDeviceStatus và scan tuần tự. Để ngăn Worker khởi động nhiều instance, phải triển khai cơ chế mutex hoặc lock file.

Cisco Catalyst/FortiGate/Yamaha RTX-NVR lấy ipNetToPhysicalTable bằng SNMP（pysnmp）. Thiết bị không hỗ trợ thì fallback sang ipNetToMediaTable. Meraki MX lấy từ endpoint /networks/{networkId}/clients bằng Dashboard API（meraki SDK）. Giá trị ban đầu của tham số thu thập SNMP: timeout 5 giây cho mỗi thiết bị・retry 2 lần・độ song song 1（tuần tự）. Chỉ cho phép điều chỉnh độ song song dựa trên kết quả đo pilot thực tế（đo 1 cycle trong tiêu chí nghiệm thu）（xác định ở v1.3）.

- Phân nhánh phương thức thu thập được điều khiển bằng ArpDeviceStatus.DeviceType（CiscoIOS/FortiGate/YamahaRTX/MerakiMX）. Thiết bị Meraki tham chiếu ArpDeviceStatus.MerakiNetworkId để gọi /networks/{MerakiNetworkId}/clients. Thiết bị có DeviceType chưa thiết lập hoặc ngoài định nghĩa sẽ bị skip thu thập, ghi vào LastErrorMessage và được tính vào đối tượng cộng ConsecutiveFailureCount（72 giờ liên tục thì chuyển Failed → đưa vào đường bảo vệ skip xóa hiện có. Đây là hành vi mặc định thiên về an toàn, phù hợp với quy định cấm silent error〔8.4〕）.（bổ sung v1.4）

Tổng hợp kết quả thu thập theo đơn vị IP（IP→MAC→thời điểm phản hồi cuối cùng）.

Trong kết quả thu thập, IP nằm trong dynamic pool（scope range − exclusion range）không thuộc đối tượng đăng ký IPAM hoặc cập nhật LastSeenAt（không lập sổ quản lý DHCP client. Đối tượng là trong dải IP cố định; với segment DhcpScopeExists=false thì là toàn bộ CIDR. xác định ở v1.1）.

Việc đăng ký・cập nhật vào IPAM không thực hiện trực tiếp từ Python; script Python xuất kết quả thu thập・đối chiếu ra JSON, và script phản ánh PowerShell chạy liên tiếp trong cùng task sẽ thực hiện xử lý（vì IPAM chỉ thao tác được thông qua PowerShell module. xác định ở v1.1）.

Phán định kết quả theo từng lần xử lý thiết bị và cập nhật Upsert list ArpDeviceStatus（LastSuccessAt, LastAttemptAt, ConsecutiveFailureCount, CurrentStatus, LastErrorMessage）.

Khi thành công: reset CurrentStatus=OK・ConsecutiveFailureCount=0. Khi chuyển Failed→OK cũng không thông báo.

Khi thất bại: increment ConsecutiveFailureCount.

Khi đạt ConsecutiveFailureCount=72（thất bại liên tục 72 giờ）: thiết lập CurrentStatus=Failed・gửi 1 thông báo tới nkis-network・cập nhật LastNotifiedAt.

Khi ConsecutiveFailureCount\>72 và thời điểm hiện tại − LastNotifiedAt ≧ 24 giờ: gửi thông báo nhắc lại・cập nhật LastNotifiedAt.

Với từng IP, query IPAM và phân nhánh theo trạng thái đăng ký. Điều kiện phán định chỉ gồm “trạng thái đăng ký IPAM” và “nằm ngoài dynamic pool”, trong (a)(b) không đưa IsActive vào điều kiện.（thay thế v1.4）

- **(a) Trường hợp đã đăng ký và Source có chứa giá trị Cooldown（nhánh khôi phục từ Cooldown）**: Theo quy chuẩn khôi phục của 7.4（※ ghi chú cooldown sau xóa）, thực hiện khôi phục theo thứ tự sau — (1) cập nhật LastSeenAt bằng thời điểm phát hiện（thực hiện đầu tiên）, (2) loại bỏ giá trị Cooldown khỏi Source và đặt Source=AutoDetected bất kể giá trị Source gốc（không khôi phục DNS record・sổ đăng ký）, (3) clear CooldownStartedAt, (4) clear RequestId. MacAddress không thao tác trong xử lý khôi phục（các cập nhật sau đó tuân theo quy tắc MAC hiện có từ (b) trở đi）. Nếu giá trị Source gốc bị loại bỏ có chứa Requested thì gửi thông báo khôi phục tới nkis-network（Phụ lục F#14）. Nhánh này được thực hiện không phụ thuộc giá trị IsActive hay việc có thuộc segment loại trừ hay không（đây là bảo toàn IP đã đăng ký hiện có, cùng nhóm với việc tiếp tục cập nhật LastSeenAt ở 3.1）.

  **(b) Trường hợp đã đăng ký và không chứa giá trị Cooldown**: Như trước đây, chỉ cập nhật LastSeenAt（chỉ ghi khi đã trôi qua từ 24 giờ trở lên so với giá trị trước đó. Không đưa IsActive vào điều kiện. Duy trì quy định v1.2）.

  **(c) Trường hợp chưa đăng ký**: Tự động đăng ký（Add-IpamAddress, Source=AutoDetected, MacAddress=giá trị phát hiện, LastSeenAt=thời điểm phát hiện）. Tuy nhiên, nếu segment mà IP đó thuộc về có IsActive=false hoặc RangeChangePending=true thì không thực hiện đăng ký mới（trường hợp trước phù hợp với quy định ngoài phạm vi ở 3.1〔đăng ký＝loại trừ／cập nhật＝không phụ thuộc là thiết kế bất đối xứng có chủ ý〕, trường hợp sau theo quy định giữ đăng ký dưới đây）.

  ※ Đối tượng bị giữ chỉ là đăng ký AutoDetected mới; việc cập nhật LastSeenAt của entry hiện có（(a)(b)）vẫn tiếp tục trong thời gian thay đổi phạm vi（không cuốn việc bảo toàn IP hiện có vào trạng thái giữ）. IP phát hiện bị giữ sẽ được đánh giá ở chu kỳ tiếp theo（sau khi phản ánh phạm vi）. Độ trễ tối đa là hơn 1 chu kỳ và được xem là phạm vi chấp nhận.（tạo mới v1.4）

【v1.4: Điều khoản này đã được gộp vào nhánh (c) của thủ tục 44, vì vậy xóa toàn bộ đoạn. Ở \#14 cần xóa đoạn〔xóa cả \<w:numPr\>〕chứ không phải chỉ bỏ gạch ngang】

Đối với IP đã đăng ký nhưng chưa thiết lập MAC, liên kết giá trị MAC phát hiện được（chỉ lần đầu）. Nếu phát hiện MAC khác nhau cho cùng một IP thì ưu tiên timestamp mới nhất và ghi đè MAC. Nếu Source=Requested thì thông báo tới nkis-network như nghi ngờ xung đột IP; nếu AutoDetected thì không thông báo（thay đổi v1.1）.

Lịch sử thực thi thu thập ARP được ghi vào custom log chuyên dụng “IPAM-Worker” của Windows Event Log. Event ID: 1001=thành công／1002=thất bại một phần／1003=thất bại toàn bộ.

## 7.4 Luồng tự động xóa（hằng ngày）

Worker tự động xóa quét IPAM hằng ngày（nửa đêm JST）và thực hiện xử lý tùy theo số ngày đã trôi qua kể từ LastSeenAt（theo đơn vị ngày: 30/90/180/365 ngày）.

Số ngày đã trôi qua được tính theo quy ước tính ngày ở 6.8, bằng cách trừ SkippedDays（6.3）của segment tương ứng. Hiệu chỉnh này được áp dụng chung cho toàn bộ các phán định: xóa AutoDetected sau 30 ngày, phán định giai đoạn của Requested（90/180/365 ngày）và phán định hết hạn Cooldown（thời gian đóng băng không tiêu thụ thời gian gia hạn. thay đổi yêu cầu=A-1. Phù hợp với mục 1 “Giới hạn đã biết” và yêu cầu A-1 trong Phụ lục B）. Các phán định số ngày trong bảng xóa, tính toán giai đoạn mục tiêu và sub-flow hết hạn bên dưới đều được đánh giá bằng số ngày đã trôi qua sau hiệu chỉnh này. Hiệu chỉnh này chỉ áp dụng một lần ở phía số ngày đã trôi qua, không cộng/trừ thêm “+SkippedDays” riêng trong từng công thức phán định（quy ước tính ngày ở 6.8-2 là bản chuẩn）.（bổ sung v1.4）

【Xác định chi tiết đăng ký từ entry IPAM】Khi Worker tự động xóa cập nhật NotificationStage・Status chi tiết và xác định đối tượng xóa DNS, việc xác định chi tiết được thực hiện bằng cách trích xuất ID item chi tiết từ custom field RequestId của IPAM（định dạng “REQ-yyyymmdd-{ID item cha}-{ID item chi tiết}”. xem 6.8）, rồi tham chiếu trực tiếp IPRequestItems. Hostname thuộc đối tượng xóa DNS sử dụng AssignedFqdn của chi tiết đó. Entry có RequestId rỗng（AutoDetected・sau khi khôi phục từ Cooldown）được xem là không join với chi tiết, nên không thuộc đối tượng quản lý giai đoạn và xóa DNS. Nếu phát hiện entry Source=Requested nhưng RequestId rỗng hoặc sai định dạng, xem là bất thường về tính nhất quán, thông báo tới nkis-network và skip xử lý chuyển trạng thái của entry đó.（tạo mới v1.4）

Worker tự động xóa chỉ ghi NotificationStage khi có chuyển trạng thái. Việc tính giai đoạn mục tiêu và ghi chuyển trạng thái không áp dụng cho entry có Source chứa giá trị Cooldown（entry Cooldown chỉ được đánh giá trong sub-flow hết hạn）. Worker tính giai đoạn mục tiêu từ số ngày đã trôi qua（dưới 90 ngày=None／90〜179 ngày=3M-Reminder／180〜364 ngày=6M-Reminder／365 ngày trở lên=12M-Deleted）và chỉ ghi khi khác với giá trị hiện tại. Số ngày đã trôi qua sử dụng giá trị sau hiệu chỉnh ở 6.8-2（không áp dụng lặp lại hiệu chỉnh trong phần mở đầu này）.

Cách xử lý NotificationSentAt khi ghi: nếu NotificationSentAt của chi tiết đó chưa được thiết lập thì clear trong cùng lần cập nhật（duy trì trạng thái chưa thiết lập）. Chỉ khi ghi đè phục hồi từ giá trị hiện tại là Error, giữ lại SentAt của chi tiết đã gửi（đã thiết lập SentAt）（ngăn gửi lại do vòng lặp khôi phục Error. Với tiến trình giai đoạn thông thường〔3M→6M, v.v.〕, khi chuyển giai đoạn sẽ clear để gửi thông báo của giai đoạn tiếp theo）. Ngay cả khi giá trị hiện tại là Error, cũng ghi đè bằng giai đoạn mục tiêu theo quy tắc này（đường tự động phục hồi từ trạng thái Error）.

Khi phản hồi ARP phục hồi và số ngày đã trôi qua quay về dưới ngưỡng, giai đoạn mục tiêu sẽ là None, và theo cùng quy tắc sẽ thực hiện chuyển lùi và clear SentAt. Tuy nhiên, các chi tiết có Status=Archived không thuộc đối tượng chuyển lùi（ghi giai đoạn mục tiêu=None）（bảo toàn lịch sử thông báo của chi tiết đã thực hiện xóa）.

Kích hoạt lại（idempotent touch）: với các chi tiết có giai đoạn mục tiêu trùng giá trị hiện tại, NotificationSentAt chưa thiết lập, và đã trôi qua từ 1 ngày trở lên kể từ lần ghi chuyển sang giai đoạn đó（trừ None, bao gồm cả 12M-Deleted）, thực hiện ghi lại cùng một giá trị để kích hoạt lại trigger Power Automate（Worker tự động kích hoạt lại các chi tiết bị treo do lỗi phía notification flow, chưa gửi hoặc chưa ghi nhận. Việc phán định đã gửi dựa trên SentAt nên không phát sinh gửi trùng）.

Giới hạn đã biết: nếu Error bị tồn đọng qua ranh giới số ngày（90/180/365 ngày）, khi phục hồi có thể thiếu tối đa 1 giai đoạn thông báo（giới hạn cấu trúc do chỉ có một field SentAt. Ở lần chuyển sang giai đoạn tiếp theo sẽ clear, nên thông báo xóa cuối cùng 12M vẫn được đảm bảo）.（thay thế v1.4）

**【Xử lý đầu tiên: tham chiếu ArpDeviceStatus】**

Worker tự động xóa tính toán lại danh sách segment loại trừ tại runtime từ giá trị hiện tại của list Segments và list ArpDeviceStatus ở thời điểm bắt đầu quét. Segment loại trừ là hợp của (i) TargetSegments của thiết bị có CurrentStatus=Failed và (ii) segment chưa được cover（CIDR của Segments không nằm trong bất kỳ ArpDeviceStatus.TargetSegments nào）. Phán định này áp dụng cho toàn bộ segment không phụ thuộc giá trị IsActive（tham chiếu cách phân biệt ở 3.1）. Không tham chiếu Segments.CoverageStatus（cột này dùng cho hạn chế thông báo・audit. xem 6.3）.（thay thế v1.4）

Với từng segment nằm trong danh sách segment loại trừ, cộng 1 vào Segments.SkippedDays và ghi ngày thực thi vào LastSkipDate（tích lũy số ngày đóng băng của đánh giá xóa. xem 6.3）.（bổ sung v1.4）

Nếu danh sách segment loại trừ không rỗng, hoặc trong ngày đó tồn tại từ 1 entry trở lên bị giữ phán định xóa do không thuộc range（giữ xóa theo predicate theo đơn vị IP ở 7.4-3）, gửi thông báo skip xóa（Phụ lục F#15）tới nkis-network. Trong thông báo, ghi phân biệt lý do skip（do thiết bị Failed／do chưa cover／do không thuộc range）; với lý do do thiết bị Failed thì ghi thiết bị nguyên nhân・thời gian thất bại liên tục, với lý do chưa cover thì ghi thiếu TargetSegments phụ trách, với lý do không thuộc range thì ghi IP đối tượng bị giữ xóa theo predicate theo đơn vị IP ở 7.4-3; đồng thời, bất kể lý do, ghi số ngày tiếp tục skip（với lý do thiết bị Failed・chưa cover là giá trị SkippedDays. Với lý do không thuộc range là lý do theo đơn vị IP nên không gắn SkippedDays theo đơn vị segment）. Ngay cả ngày có 0 segment loại trừ nhưng chỉ tồn tại IP bị giữ do không thuộc range, điều kiện này cũng kích hoạt \#15.（thay thế v1.4・bổ sung v1.4）

Tập loại trừ là snapshot tại thời điểm bắt đầu quét; thay đổi trạng thái thiết bị trong khi quét（chuyển sang Failed, v.v.）sẽ được phản ánh từ lần chạy ngày hôm sau. Mọi tham chiếu Segments trong flow này（bao gồm phán định segment loại trừ, phán định thuộc range ở 7.4-3, tham chiếu SkippedDays và xác định segment trong sub-flow hết hạn）đều sử dụng cùng snapshot tại thời điểm bắt đầu quét（để tiêu chí phán định không dao động ngay cả khi Worker đồng bộ thay đổi range bằng Set-IpamRange trong lúc quét. Thay đổi trong khi quét phản ánh từ lần chạy ngày hôm sau. Cùng kiểu với mục 6 “Giới hạn đã biết” ở Phụ lục B）.（thay thế v1.4）

Trong các entry IPAM thuộc đối tượng quét, entry có IP không thuộc bất kỳ IPAM range nào（Segments.StaticIpRangeRaw. Với segment DhcpScopeExists=false thì là toàn bộ CIDR）sẽ không thuộc đối tượng phán định xóa・chuyển giai đoạn（IP bị ngoài phạm vi＝queue phán định thủ công. tham chiếu quy định khi thu hẹp phạm vi ở 7.2）. Entry bị giữ phán định xóa bởi predicate này trong ngày sẽ thuộc đối tượng kích hoạt và ghi trong thông báo skip xóa ở trên（#15）（lý do do không thuộc range）. Tuy nhiên, entry có Source chứa giá trị Cooldown không thuộc đối tượng giữ này; ngay cả khi không thuộc range, vẫn xóa vật lý khi hết hạn Cooldown（thu hồi phần còn sót Cooldown của vùng trả lại phạm vi khỏi sổ. Vì đường quan sát đã bị đóng tại thời điểm ngoài phạm vi nên dù giữ cũng không khôi phục）.（tạo mới v1.4）

| **Source** | **Thời gian không phản hồi** | **Action** | **Thông báo** |
|----|----|----|----|
| AutoDetected | 1 tháng | Xóa（chuyển từ IPAM sang Cooldown. Giữ 30 ngày rồi xóa vật lý） | Không có（xem là IP không chính quy） |
| Requested | 3 tháng | Không xóa | Cập nhật chi tiết NotificationStage=3M-Reminder → Power Automate gửi thông báo tổng hợp（người đăng ký） |
| Requested | 6 tháng | Không xóa | Cập nhật chi tiết NotificationStage=6M-Reminder → Power Automate gửi thông báo tổng hợp（người đăng ký + Manager） |
| Requested | 12 tháng | Xóa archive（IPAM+DNS）, chi tiết Status=Archived（khi toàn bộ chi tiết Archived thì record cha cũng Archived） | Cập nhật chi tiết NotificationStage=12M-Deleted → Power Automate gửi thông báo tổng hợp（người đăng ký + Manager） |

※（Bổ sung cho dòng 12 tháng trong bảng xóa）Việc cập nhật chi tiết Status=Archived và tổng hợp IPRequests.Status=Archived của cha khi toàn bộ chi tiết đã Archived được Worker tự động xóa thực hiện trong cùng xử lý với việc xóa（quy tắc tổng hợp tuân theo tổng hợp Status cha ở 7.1）.（bổ sung v1.4）

※ Trong vòng lặp phán định xóa, skip các IP thuộc segment loại trừ（không đánh giá số ngày đã trôi qua từ LastSeenAt）. IP thuộc segment loại trừ sẽ được skip cả phán định xóa・chuyển giai đoạn dựa trên LastSeenAt lẫn xóa vật lý hết hạn dựa trên CooldownStartedAt（không đưa IP Cooldown đã hết hạn vào pool trống trong lúc mất quan sát. Số ngày đóng băng được hiệu chỉnh bằng SkippedDays）.（bổ sung v1.4）

【Bộ đệm khi gỡ skip】Ở lần thực thi tự động xóa đầu tiên sau khi nguyên nhân skip theo đơn vị segment（do thiết bị Failed／do chưa cover）được giải quyết — tức là segment có LastSkipDate là ngày hôm trước（ngày hôm trước skip được áp dụng, còn ngày hiện tại segment đó không thuộc đối tượng skip）. Để bắt các trường hợp bị bỏ sót khi chu kỳ bị quá hạn, điều kiện phán định là “LastSkipDate từ ngày chạy trước trở đi và ngày hiện tại không áp dụng skip”（ngày chạy trước được lấy chỉ đọc từ lịch sử thực thi ở 8.4〔bản ghi lần chạy trước trong Windows Event Log “IPAM-Worker”〕. Đây không phải là lưu trạng thái local ảnh hưởng tới phán định xóa/loại trừ. Nếu không lấy được ngày chạy trước từ lịch sử thực thi〔do rotate event log, v.v.〕, lần chạy đó không áp dụng bộ đệm và thực hiện phán định giai đoạn bình thường〔bộ đệm sẽ hoạt động từ lần chạy sau〕. Hiệu chỉnh SkippedDays của số ngày đã trôi qua không bị ảnh hưởng bởi fallback này và luôn được áp dụng.（bổ sung v1.4））— áp dụng quy tắc bộ đệm sau: (a) chuyển giai đoạn（NotificationStage）tối đa 1 giai đoạn trong 1 lần chạy. (b) Không thực hiện xóa archive 12 tháng ở “lần chạy đầu tiên sau khi gỡ” đó, mà chuyển sang lần chạy sau（đây là việc trì hoãn nhằm chèn tối thiểu 1 cycle thu thập ARP〔1 giờ. tiền đề điều chỉnh theo đo thực tế〕sau khi gỡ để có cơ hội cập nhật LastSeenAt; không cần ghi thời điểm gỡ. Ý nghĩa tương đương）. Xóa vật lý hết hạn Cooldown có cơ chế xác nhận 1 ngày（phương thức +31 ngày）hoạt động như bộ đệm tương đương.（thay thế v1.4）

※ Đối tượng áp dụng bộ đệm chỉ giới hạn ở nguyên nhân skip theo đơn vị segment（do thiết bị Failed・do chưa cover）. Không áp dụng bộ đệm cho skip do không thuộc range（giữ xóa theo predicate theo đơn vị IP ở 7.4）. Lý do: không thuộc range là nguyên nhân theo đơn vị IP đi kèm thay đổi phạm vi（thao tác có chủ đích của vận hành viên）, trong khi dữ liệu phán định bộ đệm（bản ghi skip ngày trước＝LastSkipDate）chỉ có ở mức segment; hơn nữa ngay cả khi không có bộ đệm thì tác hại thực tế nhỏ（có thể phát sinh tối đa 1 email reminder sai khi đánh giá hàng loạt sau khi khôi phục phạm vi＝chấp nhận như hành vi mặc định thiên về an toàn）. Không lưu thời điểm kết thúc trạng thái không thuộc range hoặc dữ liệu phát hiện gỡ trong phần thân tài liệu, và xử lý dứt khoát là ngoài đối tượng bộ đệm.（thay thế v1.4）

※ Hiệu chỉnh SkippedDays（hiệu chỉnh đóng băng số ngày đã trôi qua）là lớp bảo vệ thứ nhất; bộ đệm này là lớp thứ hai cho các nguyên nhân mà hiệu chỉnh không bao phủ（do không thuộc range＝theo đơn vị IP nên không áp dụng hiệu chỉnh theo đơn vị segment）và các case biên.（tạo mới v1.4）

※ Chỉ xóa DNS record đối với IP Source=Requested và đã đăng ký hostname.

※ Cooldown sau xóa: giữ trong IPAM với giá trị Source=Cooldown trong 30 ngày. Sau 30 ngày sẽ xóa vật lý（trả về pool IP trống）. Khi chuyển sang Cooldown, gán thêm giá trị Cooldown vào Source（giữ giá trị gốc）. Khi chuyển sang Cooldown, ghi thời điểm thực hiện xóa vào custom field CooldownStartedAt của IPAM（điểm bắt đầu tính. xem 6.8）. Xử lý khôi phục（script phản ánh IPAM của Worker thu thập ARP thực hiện đồng thời khi phát hiện. Khôi phục thủ công của bộ phận IT cũng tuân theo cùng thủ tục）được thực hiện theo thứ tự sau đối với entry IPAM đó: (1) cập nhật LastSeenAt bằng thời điểm phát hiện（thực hiện đầu tiên. Ngay cả khi các thao tác sau thất bại một phần, điều kiện (3) của sub-flow hết hạn sẽ ngăn xóa）, (2) loại bỏ giá trị Cooldown khỏi Source và đặt Source=AutoDetected bất kể giá trị Source gốc（không khôi phục DNS record・sổ đăng ký）, (3) clear CooldownStartedAt, (4) clear RequestId. MacAddress không thao tác trong xử lý khôi phục（giữ nguyên. Các cập nhật sau đó giao cho quy tắc hiện có ở 7.3〔ưu tiên timestamp mới nhất〕）. Khi khôi phục entry có nguồn gốc Requested（giá trị Source gốc bị loại bỏ có chứa Requested）, thông báo tới nkis-network（Phụ lục F#14）. Ghi chú này là bản chuẩn về các field cần clear/giữ; nhánh khôi phục ở 7.3 và xử lý thủ công ở 10.7 phải tuân theo.（thay thế v1.4）

**【Sub-flow xóa vật lý khi hết hạn Cooldown】**

Chủ thể thực thi là Worker tự động xóa（hằng ngày）. Các entry Cooldown（entry có Source chứa giá trị Cooldown）đã bị loại khỏi match số ngày đã trôi qua trong bảng xóa và khỏi tính toán giai đoạn mục tiêu sẽ chỉ được đánh giá trong sub-flow này.

Predicate phán định hết hạn: ngày thực thi ≥ CooldownStartedAt + 30 ngày + 1 ngày（đánh giá bằng số ngày đã trôi qua sau hiệu chỉnh ở 6.8-2. “+1 ngày” là ngày xác nhận trước khi xác định xóa. Hiệu chỉnh SkippedDays của segment tương ứng đã được áp dụng ở phía số ngày đã trôi qua của 6.8-2, nên không cộng thêm “+SkippedDays” riêng trong predicate này）. Với entry không thuộc range mà không thể xác định “segment tương ứng”（phần còn sót Cooldown của vùng trả lại phạm vi, thuộc đối tượng xóa vật lý hết hạn theo ngoại lệ ở 7.4-3）, đánh giá với SkippedDays=0（vì tiền đề là đường quan sát đã bị đóng và không khôi phục, nên hiệu chỉnh 0 không gây hại）.（bổ sung v1.4）

Điều kiện bổ sung khi thực hiện xóa: ngoài việc predicate thỏa mãn, chỉ khi thỏa cả 2 điều kiện (2) Source vẫn còn chứa giá trị Cooldown và (3) LastSeenAt ≤ CooldownStartedAt thì mới xóa vật lý bằng Remove-IpamAddress và trả về pool IP trống. Nếu không thỏa bất kỳ điều kiện nào thì không xóa và skip（xem như xử lý khôi phục đang tiến hành hoặc đã hoàn tất, và xử lý về sau tuân theo bản chuẩn khôi phục）.

Khi CooldownStartedAt rỗng: dùng LastSeenAt + 30 ngày + 1 ngày làm điểm bắt đầu thay thế（hiệu chỉnh SkippedDays đã được áp dụng ở phía số ngày đã trôi qua của 6.8-2）để phán định, đồng thời gửi thông báo chỉnh sửa dữ liệu tới nkis-network（với điểm bắt đầu thay thế, việc cập nhật LastSeenAt sẽ tự động trì hoãn xóa, nên tạo ra bảo vệ tương đương điều kiện (3). Điều kiện (2) vẫn áp dụng tương tự）.

Sub-flow này thuộc đối tượng áp dụng danh sách segment loại trừ（entry Cooldown thuộc segment loại trừ sẽ bị skip ngay cả khi đã hết hạn, và được đưa vào Phụ lục F#15）. Việc giữ xóa đối với entry không thuộc range không áp dụng cho sub-flow này（theo ngoại lệ Cooldown của xử lý đầu tiên）.

DNS record đã được xóa khi chuyển sang Cooldown, nên sub-flow này không thao tác DNS.（tạo mới v1.4）

※ Khi gửi thông báo, Power Automate lấy thuộc tính manager mỗi lần bằng Office 365 Users connector（gửi tới Manager hiện tại tại thời điểm thông báo. Worker không cần quyền Graph đọc directory）. Khi phát sinh bất thường như không tìm thấy UPN người đăng ký hoặc không lấy được thuộc tính Manager, gửi thông báo bất thường tới nkis-network@nkc.co.jp và ghi log. Việc ghi NotificationStage=Error và gửi thông báo bất thường tới nkis-network được chính notification flow đó thực hiện đồng thời khi bắt lỗi（không tạo Phụ lục F#7 thành flow trigger độc lập. xác định ở v1.3）. Phạm vi ghi Error được quyết định theo vị trí lỗi trong flow: (a) lỗi trước khi resolve người nhận（lấy UPN/Manager）hoặc gọi gửi mail được xem là lỗi chung theo đơn vị tổng hợp, ghi Error cho toàn bộ chi tiết thuộc đối tượng tổng hợp（vì tại thời điểm này chưa tồn tại chi tiết đã gửi, nên toàn bộ sẽ được tổng hợp lại ở lần kích hoạt lại ngày hôm sau）. (b) lỗi trong quá trình cập nhật NotificationSentAt sau khi gửi thành công được xem là lỗi riêng từng chi tiết, chỉ ghi Error cho chi tiết trigger（các chi tiết chưa cập nhật sẽ được thu hồi bằng query lại của flow tổng hợp và idempotent touch của Worker）. Trong mọi trường hợp, ghi Error là thao tác đầu tiên trong xử lý bắt lỗi của flow（ưu tiên đảm bảo mầm kích hoạt lại）.

Quy định này áp dụng cho flow gửi tổng hợp liên động NotificationStage（đường chung của Phụ lục F#4〜#6）. Thông báo hoàn tất \#2 và thông báo thất bại \#3 không lấy Manager và người nhận chỉ là người đăng ký, nên không phải đối tượng chính của quy định này; khi phát sinh bất thường thì tuân theo quy định cấm silent error ở 8.4（đảm bảo đến được nkis-network）.（thêm v1.4）

※ Gửi thông báo tổng hợp（v1.1）: Power Automate lấy thay đổi của IPRequestItems.NotificationStage làm trigger（độ song song flow = 1）, tổng hợp các chi tiết có cùng ParentItemId・cùng NotificationStage・NotificationSentAt chưa thiết lập và gửi trong 1 email（trong nội dung ghi danh sách IP/hostname thuộc đối tượng）. Sau khi gửi, cập nhật NotificationSentAt của từng chi tiết. Vì SharePoint trigger không có cơ chế phát hiện thay đổi theo từng cột, cần ngăn phát hỏa nhiều lần bằng điều kiện trigger và phán định đã gửi dựa trên NotificationSentAt.

【Quy ước chung của notification flow】（áp dụng chung cho flow tổng hợp liên động NotificationStage〔#4〜#6〕, thông báo hoàn tất \#2, thông báo thất bại \#3）: (1) Độ song song của flow là 1. (2) Thứ tự gửi và ghi nhận đã gửi là “xác nhận gửi email thành công → cập nhật cột guard（NotificationSentAt／CompletionNotifiedAt／FailureNotifiedAt）”. Nếu thất bại sau khi gửi thành công nhưng trước khi ghi nhận, lần phát hỏa tiếp theo sẽ xem là chưa ghi nhận và gửi lại（cho phép gửi lại idempotent. Không áp dụng phương thức 2 phase bằng marker đang gửi vì cột guard là kiểu ngày giờ và không có miền giá trị marker）. (3) Trigger là at-least-once delivery, việc ngăn phát hỏa nhiều lần được thực hiện bằng tổ hợp tuần tự hóa do độ song song 1 và phán định đã gửi bằng cột guard（các biện pháp giảm số lần trigger như gộp PATCH phía cha không thể đơn độc loại bỏ gửi trùng）.

【Quy định riêng cho thông báo xóa（#4〜#6）】: Sau khi trigger phát hỏa, flow tổng hợp sẽ query lại các chi tiết “cùng ParentItemId・cùng NotificationStage・NotificationSentAt chưa thiết lập” để xác định tập mẹ tổng hợp, rồi gửi trong 1 email（tránh tổng hợp thiếu khi Worker đang ghi tuần tự）. Worker tự động xóa về nguyên tắc hoàn tất ghi các chi tiết cùng ParentItemId・cùng giai đoạn mục tiêu trong cùng một cycle thực thi. Ngay cả khi việc ghi vượt sang cycle tiếp theo, trigger của lần ghi sau sẽ query lại và thu hồi các chi tiết chưa gửi, vì vậy cuối cùng sẽ hội tụ mà không thiếu hoặc trùng（tự phục hồi phần carry-over）.

【Hành vi đã biết】Trong thời gian lỗi ghi SharePoint tiếp diễn, có thể nhận nhiều thông báo cùng một giai đoạn（cho phép gửi lại. Các chi tiết đã ghi nhận gửi thành công sẽ không bị gửi lại）. Khi xác định nội dung thông báo（chương 13）, cần xem xét câu chữ với tiền đề có thể có gửi lại.（thêm v1.4）

※ Về các giới hạn đã biết của flow này（cửa sổ không được bảo vệ 72 giờ trước khi chuyển Failed, cửa sổ 1 đêm của snapshot tại thời điểm bắt đầu quét, thiếu tối đa 1 giai đoạn thông báo khi Error vượt qua ranh giới, v.v.）, tham chiếu danh sách giới hạn đã biết trong Phụ lục B.（tạo mới v1.4）

# 8. Thiết kế Worker

## 8.1 Môi trường thực thi

Bố trí đồng cư IPAM chính và toàn bộ Worker trên Azure VM（Windows Server 2022 trở lên）.

Kích thước VM tham khảo: 4vCPU / 16GB RAM / OS disk 128GB（Premium SSD）+ data disk 128GB.

Join domain AD nội bộ（việc join domain nội bộ của Azure VM tuân theo kinh nghiệm vận hành hiện có）.

Xây dựng database IPAM bằng WID mặc định（Windows Internal Database）（với quy mô này không cần SQL Server）.

Đặt các script PowerShell（cấp phát IP・đồng bộ・tự động xóa）và script Python（thu thập ARP）trên data disk.

Thực thi định kỳ bằng Task Scheduler. Tài khoản thực thi là service account chuyên dụng.

Cài đặt môi trường thực thi Python（3.11 trở lên）trên Worker server; việc áp dụng patch runtime do team network/infrastructure vận hành.

Log được xuất dưới data disk và đưa vào đối tượng Azure Backup.

## 8.2 Quyền cần thiết

Quyền quản trị Windows IPAM（IPAM Administrators）.

Quyền đọc đối với Windows DHCP（4 máy on-premise）（tương đương DHCP Users）.

Quyền ghi zone ad.nkc.co.jp của DNS tích hợp AD và quyền ghi các reverse lookup zone tương ứng.

Quyền đọc SNMP tới các thiết bị NW thuộc đối tượng（community name hoặc tài khoản SNMPv3）.

Meraki Dashboard API key（quyền Read-Only, theo đơn vị tổ chức）.

Xác thực Microsoft Graph API bằng đăng ký ứng dụng Entra ID + xác thực chứng chỉ（quyền tối thiểu: chỉ truy cập SharePoint list）.

## 8.3 Các command・library chính sử dụng

**PowerShell（thao tác Windows IPAM/DHCP/DNS）**

Find-IpamFreeAddress: tìm kiếm IP trống

Add-IpamAddress, Set-IpamAddress, Remove-IpamAddress, Get-IpamAddress: thao tác IPAM

Add-IpamCustomField, Add-IpamCustomValue: định nghĩa custom field（chỉ lần đầu）

Add-IpamSubnet, Add-IpamRange, Set-IpamRange: tạo・đồng bộ subnet/range IPAM（quản lý tập mẹ của dải IP cố định. thêm v1.1）

Get-DhcpServerv4OptionValue: lấy scope option như Gateway/DNS server（thêm v1.1）

Send-MailMessage hoặc System.Net.Mail.SmtpClient: gửi alert qua SMTP relay nội bộ（thêm v1.1）

Get-DhcpServerv4Scope, Get-DhcpServerv4ExclusionRange: lấy DHCP scope・exclusion range

Add-DnsServerResourceRecordA（kèm -CreatePtr）, Remove-DnsServerResourceRecord: thao tác DNS record

Resolve-DnsName: kiểm tra trùng DNS（chỉ định rõ DNS server giống nơi ghi bằng -Server để tránh bỏ sót trùng lặp do độ trễ replication AD）

Invoke-RestMethod: đọc/ghi SharePoint list thông qua Graph API

Write-EventLog: ghi vào Windows Event Log “IPAM-Worker”

New-EventLog / Limit-EventLog: tạo lần đầu và thiết lập kích thước custom event log “IPAM-Worker”（event log tối đa 512MB・chế độ ghi đè. File log rotate hằng ngày・giữ 90 ngày. xác định ở v1.3）

**Python（thu thập ARP）**

pysnmp hoặc easysnmp: SNMP walk（Cisco/FortiGate/Yamaha）

meraki（SDK chính thức）: Meraki Dashboard API

netmiko + ntc-templates（TextFSM）: dùng cho tự động hóa sổ thiết bị trong tương lai（triển khai ban đầu ưu tiên SNMP）

ipaddress（standard library）: phép toán tập hợp IP

msal: xác thực Microsoft Graph API（dùng để cập nhật ArpDeviceStatus）

smtplib（standard library）: gửi alert qua SMTP relay nội bộ（thêm v1.1）

## 8.4 Chính sách xử lý lỗi

Cấm silent error: mọi exception bắt buộc phải được ghi log + đưa tới đường thông báo（người đăng ký hoặc nkis-network）.

Phát hiện 100% trùng IP khi đăng ký・cấp phát: kiểm tra trùng đăng ký qua 3 tuyến IPAM registration・cấp phát・ARP detection; khi phát hiện thì thông báo ngay tới nkis-network. Nghi ngờ xung đột IP trong vận hành（phát hiện MAC khác với MAC đã đăng ký đối với IP có Source=Requested）sẽ thông báo tới nkis-network đồng thời với việc ghi đè MAC.

Giới hạn RetryCount là 3 lần: khi đạt giới hạn thì xác định Status=Failed + gửi thông báo escalation tới nkis-network.

Ngăn Worker khởi động nhiều instance: ghi rõ yêu cầu triển khai cơ chế mutex hoặc lock file. Khi dùng lock file, ghi process ID giữ lock và thời điểm lấy lock; khi khởi động, kiểm tra process giữ lock còn sống hoặc phán định hết hạn theo timestamp（hết hạn khi vượt quá giới hạn thời gian dự kiến của Worker）để tự động giải phóng lock còn sót（ngăn việc từ chối khởi động vĩnh viễn do lock rác sau crash）. Khi dùng lock file cho cơ chế loại trừ giữa các Worker（mục tiếp theo）, cũng tuân theo cùng quy ước tự động hết hạn.（thay thế v1.4）

Loại trừ giữa các Worker（cập nhật entry IPAM）: để Worker tự động xóa（hằng ngày 02:00）và xử lý phản ánh IPAM của Worker thu thập ARP không cập nhật đồng thời cùng một entry IPAM, thực hiện mutual exclusion bằng named mutex theo đơn vị entry, dùng địa chỉ IP làm key. Chỉ giữ lock trong khoảng thao tác cập nhật entry đó. Timeout chờ ở mức vài giây（ví dụ: 10 giây, điều chỉnh theo đo thực tế）; khi vượt timeout thì skip entry đó và tiếp tục xử lý（phía phản ánh ARP đánh giá lại ở cycle sau, phía xóa đánh giá lại vào ngày hôm sau. Xác nhận +1 ngày của sub-flow hết hạn Cooldown và guard LastSeenAt là safety net nên skip là hướng an toàn）. Không áp dụng global lock（1 lock cho toàn bộ）vì sẽ gây dừng toàn bộ phản ánh ARP trong lúc quét 02:00 → vượt chu kỳ → kéo theo thiếu cycle. tạo mới v1.4

Hành vi khi vượt chu kỳ: nếu việc thực thi của từng Worker vượt quá thời điểm khởi động lần tiếp theo, cycle tiếp theo sẽ bị skip bởi cơ chế ngăn khởi động nhiều instance（cho phép thiếu cycle, không thực thi kép）. Việc phát sinh skip được ghi vào event log, và script giám sát（10.4・đường Phụ lục F#20）phát hiện tình trạng vượt chu kỳ/skip thường xuyên rồi thông báo. Thời gian quét của từng Worker được đo khi nghiệm thu（bổ sung thời gian quét của Worker tự động xóa・Worker đồng bộ vào đo thực tế 1 cycle ARP ở 11.3）, để xác nhận tính hợp lý của thiết kế chu kỳ. tạo mới v1.4

Safety thu thập ARP: áp dụng pattern β theo đơn vị thiết bị. Khi thất bại liên tục 72 giờ, gửi thông báo chuyển Failed và skip tự động xóa các segment do thiết bị Failed phụ trách.

Đảm bảo idempotency. Ngay cả khi chạy nhiều lần với cùng RequestId cũng không cấp phát trùng, bằng cách điều khiển loại trừ bằng status Processing. Phát hiện cấp phát trùng được thực hiện bằng lỗi uniqueness của Add-IpamAddress và kiểm tra đã đăng ký bằng key theo đơn vị chi tiết（loại bỏ cửa sổ race của check-then-act. Chi tiết xem 7.1. thay đổi v1.2）. Trạng thái trung gian của Worker đồng bộ（range đã cập nhật・Segments chưa cập nhật, v.v.）sẽ tự phục hồi bằng cập nhật sai khác toàn bộ ở lần chạy tiếp theo（7.2）. Worker cấp phát IP sẽ sửa trạng thái thiếu tổng hợp Status cha bằng sửa tổng hợp cha ở đầu cycle（7.1）. Quy ước triển khai là mọi crash・gián đoạn đều hội tụ bằng chạy lại ở cycle tiếp theo.（thêm v1.4）

Thu hồi Processing bị tồn đọng: chi tiết vẫn ở Processing quá 30 phút kể từ lần cập nhật cuối sẽ được trả về Pending và gửi cảnh báo tới nkis-network（thêm v1.1）. Khi trả về Pending, cộng RetryCount; khi đạt giới hạn thì rollback IPAM（bao gồm xóa DNS record nếu đã đăng ký DNS）rồi xác định Failed（bất kể đường cộng nào, kết thúc ở giới hạn 3 lần. Chi tiết xem 7.1）.（thêm v1.4）

Externalize ngưỡng ngày: các ngưỡng ngày dùng cho phán định xóa（30 ngày／90 ngày／180 ngày／365 ngày, Cooldown 30 ngày, các tham số thời gian như bộ đệm khi gỡ skip）không hard-code trong Worker mà lưu dưới dạng tham số ngoài（file cấu hình）. Giá trị cấu hình có guard tối thiểu 7 ngày; nếu nhỏ hơn thì từ chối khi khởi động（dùng để rút ngắn ngưỡng khi kiểm thử hành vi phụ thuộc thời gian trong nghiệm thu. Nội dung đã xác định ở v1.3 được đưa rõ vào phần thân tài liệu）. Quy định giá trị vận hành trong giai đoạn chạy ban đầu theo 10.2. tạo mới v1.4

Phạm vi cho phép lưu giữ cục bộ trên Worker: chỉ cho phép Worker lưu cục bộ trạng thái hạn chế thông báo và thời điểm phát hiện đầu tiên của tình trạng tồn đọng（thời điểm RangeChangePending chuyển thành true. Nếu bị mất thì chỉ khởi động lại đếm 24 giờ và làm chậm thông báo, vẫn an toàn）. Khi mất dữ liệu này, tối đa chỉ phát sinh gửi lại thông báo nên vẫn theo hướng an toàn. Dữ liệu này được quản lý cùng cơ chế với quy ước tự động hết hạn lock file ở mục trước. Không được lưu cục bộ các trạng thái ảnh hưởng đến phán định xóa hoặc phán định loại trừ. Ngoài ra, “ngày chạy trước của Worker tự động xóa” mà trigger bộ đệm khi gỡ skip（7.4）tham chiếu sẽ được lấy chỉ đọc từ lịch sử thực thi trong Windows Event Log “IPAM-Worker”（9.3・10.4）. Đây là việc tham chiếu lịch sử đã chạy, không phải lưu cục bộ trạng thái ảnh hưởng đến phán định xóa/loại trừ trên Worker（khi mất lịch sử, chỉ có 1 lần bộ đệm không có hiệu lực, vẫn theo hướng an toàn）. Việc hạn chế thông báo lỗi truy vấn tới DHCP server đại diện（7.2）ở mức 1 lần/ngày được quản lý theo quy định này bằng bản ghi hạn chế thông báo cục bộ trên Worker（tên server × ngày JST）, không bổ sung cột vào Segments（6.3）. Tạo mới ở v1.4.

Lỗi tạm thời của Graph API sẽ được retry bằng exponential backoff（tối đa 3 lần）. Thời gian chờ ban đầu 2 giây・hệ số nhân 2（2/4/8 giây）. Đối tượng retry là 429/408/5xx/connection timeout; với 429 thì ưu tiên header Retry-After（xác định ở v1.3）.

Khi đăng ký DNS thất bại, rollback entry phía IPAM để duy trì tính nhất quán. Các lỗi do thiếu cấu hình môi trường DNS như chưa thiết lập reverse lookup zone cũng rollback tương tự và gửi thông báo lỗi môi trường tới nkis-network.

Log được xuất ra cả Windows Event Log và file log.

Email alert phát từ Worker sẽ được gửi qua SMTP relay server nội bộ（xác định ở v1.1. Địa chỉ gửi và FQDN relay được định nghĩa trong tài liệu quy trình vận hành. Cần đăng ký IP của Worker server làm nguồn được phép relay）.

## 8.5 Thông báo khi Failed

Message gửi cho người đăng ký khi đăng ký thất bại:

| **Nguyên nhân thất bại** | **Message gửi cho người đăng ký** |
|----|----|
| Trùng DNS của hostname | Hostname được chỉ định đã được đăng ký. Vui lòng đổi hostname rồi đăng ký lại. |
| Trùng DNS của hostname（do record đăng ký động. ErrorCategory=DnsDuplicateDynamic） | Hostname được chỉ định có thể đang được sử dụng bởi terminal hiện có. Nếu muốn cố định hóa hoặc thay thế terminal hiện có, vui lòng trao đổi qua IT Portal. |
| Không còn IP trống | Segment đã chọn không còn IP trống. Vui lòng liên hệ qua IT Portal. |
| Lỗi quy tắc đặt tên hostname | Hostname không khớp với quy tắc đặt tên. Vui lòng kiểm tra ghi chú trên form đăng ký rồi đăng ký lại. |
| Lỗi hệ thống（sự cố IPAM/DNS/Graph. ErrorCategory=SystemError. Bao gồm cả trường hợp xác định Failed do đạt giới hạn RetryCount, và trường hợp đạt giới hạn thông qua đường thu hồi Processing bị tồn đọng cũng thuộc phân loại này. Danh sách thời điểm thiết lập lấy ghi chú tổng hợp ở 7.1 làm chuẩn）（thay thế v1.4／chỉ sửa cột “Nguyên nhân thất bại”） | Đã xảy ra lỗi hệ thống. Vui lòng chờ một thời gian rồi đăng ký lại. Nếu vẫn không cải thiện, vui lòng liên hệ qua IT Portal.（cột message gửi cho người đăng ký không sửa đổi） |

Thông báo tới nkis-network:

Khi rollback IPAM thất bại: gửi alert khẩn cấp tới nkis-network.

Khi đạt giới hạn RetryCount: gửi thông báo escalation tới nkis-network.

Khi phát sinh skip xóa: gửi thông báo skip xóa tới nkis-network（hằng ngày, Phụ lục F#15）. Khi phát sinh skip, ghi rõ theo từng lý do, bất kể lý do là do thiết bị Failed, do chưa được cover hay do không thuộc range.（thay thế v1.4）

Khi phát hiện lỗi môi trường DNS（thiếu reverse lookup zone, v.v.）: gửi thông báo lỗi môi trường tới nkis-network（thêm v1.1）.

Khi phát sinh thu hồi Processing bị tồn đọng: gửi thông báo cảnh báo tới nkis-network（thêm v1.1）.

Nghi ngờ xung đột IP（phát hiện MAC khác đối với Source=Requested）: gửi thông báo nghi ngờ xung đột tới nkis-network（thêm v1.1）.

IP trong Cooldown quay lại hoạt động（có nguồn gốc Requested）: gửi thông báo tới nkis-network（thêm v1.1）.

Danh sách đầy đủ các event thông báo tham chiếu Phụ lục F “Danh sách thông báo”（thêm v1.1）.

# 9. Thiết kế bảo mật・phân quyền

## 9.1 Xác thực・phân quyền

Truy cập Power Apps bắt buộc xác thực bằng Entra ID. Không cho phép truy cập ẩn danh.

Quyền sử dụng Power Apps được cấp cho toàn bộ nhân viên（hoặc nhóm được chỉ định）.

Quyền chỉnh sửa trực tiếp SharePoint list chỉ cấp cho 3 thành viên team network/infrastructure. User thông thường chỉ thao tác thông qua Power Apps.

Quyền SharePoint của Power Apps: IPRequests được tạo và đọc record của chính mình; Segments/Regions/OfficeLocationMap chỉ đọc. IPRequestItems được cấp cùng quyền với IPRequests: “tạo + đọc record của chính mình（Created by = bản thân）”（xác định ở v1.3）.

Truy cập Graph API của Worker on-premise（trên Azure VM）sử dụng đăng ký ứng dụng Entra ID chuyên dụng + xác thực chứng chỉ, với quyền tối thiểu（chỉ truy cập SharePoint list）. Script giám sát（trên cùng VM, chạy hằng ngày lúc 07:00）tham chiếu chỉ đọc IPRequests/IPRequestItems trong phạm vi cùng đăng ký ứng dụng và quyền tối thiểu như Worker（dùng để phát hiện thiếu thông báo hoàn tất và tồn đọng Status cha = Pending. 10.4）. Không cấp quyền ghi cho script giám sát.（thay thế v1.4）

Cấp quyền tạo record trong list OfficeLocationMissLog cho Power Automate（service account của flow tiếp nhận đăng ký）（chủ thể ghi theo 7.1）. Tạo mới ở v1.4.

Cấp quyền đọc list Segments cho Power Automate（flow thông báo hoàn tất）（dùng để Lookup thông tin segment của \#2. 7.1）. Tạo mới ở v1.4.

Việc cấp quyền ghi cho service account vào DNS tích hợp AD（ad.nkc.co.jp và các reverse lookup zone）đã được bộ phận bảo mật phê duyệt（ghi rõ ở v1.1）.

## 9.2 Quyền service account

Thao tác IPAM được thực thi bằng service account chuyên dụng（trên Azure VM）.

Power Automate và Power Apps sử dụng lại system account hiện có đã được cấp license E5 để làm owner（xác định có điều kiện, chờ kết quả xác nhận của team phụ trách. Nếu phát hiện không phù hợp thì thảo luận lại. Ước tính C.4 được thực hiện bao gồm cả mức tiêu thụ request hiện có của account này. xác định ở v1.3）.

Meraki API key là Read-only, quy trình rotate key được định nghĩa trong tài liệu quy trình vận hành.

Chứng chỉ dùng cho Graph API sẽ được giám sát ngày hết hạn（thông báo tới nkis-network trước 60 ngày）và quy trình cập nhật được định nghĩa trong tài liệu quy trình vận hành（tham chiếu Phụ lục E. thêm v1.1）.

## 9.3 Audit

Lưu lịch sử thay đổi của toàn bộ record bằng version history của SharePoint.

Theo dõi xử lý workflow bằng lịch sử thực thi của Power Automate.

Worker ghi toàn bộ lần thực thi vào Windows Event Log（bao gồm custom log chuyên dụng “IPAM-Worker”）.

Theo dõi truy cập Power Apps bằng sign-in log của Entra ID.

Các thay đổi do Worker/Power Automate gây ra（thay đổi do hệ thống）được ghi dưới danh nghĩa service account, nhưng có thể truy vết gián tiếp về người đăng ký thông qua RequestId・event log（cách diễn giải đáp ứng yêu cầu truy vết toàn bộ đăng ký・toàn bộ thay đổi ở 3.2. xác định ở v1.3）.

Tính phù hợp của thời gian lưu giữ audit log SharePoint sẽ được xác nhận trong Phụ lục C（checklist khảo sát trước）.

# 10. Thiết kế vận hành

## 10.1 Vận hành thiết lập thủ công phía terminal

Trong thông báo hoàn tất đăng ký, ghi rõ IP, subnet mask, default gateway và DNS server. Nếu đã đăng ký hostname thì bao gồm cả FQDN.

Trong nội dung email thông báo, ghi rõ “Vui lòng đổi thiết lập thủ công sang IP mới đã được thông báo”（hướng dẫn vận hành khi IP đã đăng ký AutoDetected được cấp phát）.

Hướng dẫn thiết lập thủ công cho Windows tham chiếu tài liệu nội bộ hiện có（đăng link trong nội dung email hoàn tất đăng ký）.

Các thiết bị không phải Windows（Linux/macOS/printer/thiết bị NW/khác）do phía người đăng ký tự thiết lập. Khi cần thì liên hệ IT Portal.

Người đăng ký chịu trách nhiệm chuyển sang thiết lập static, tránh để nguyên cấu hình DHCP client.

## 10.2 Cách xử lý IP thiết lập thủ công hiện có

Các IP thiết lập thủ công hiện có sẽ được Worker thu thập ARP tự động đăng ký dưới dạng AutoDetected.

Không thiết lập vận hành để quản trị viên inventory các IP tự động phát hiện không rõ mục đích sử dụng（do hạn chế công số）.

Nếu không có phản hồi ARP trong 1 tháng（30 ngày）, IP sẽ bị tự động xóa như IP không chính quy. Tuy nhiên trong giai đoạn vận hành ban đầu（khuyến nghị 90 ngày sau khi bắt đầu ledger hóa ARP, tiền đề điều chỉnh theo đo thực tế）, do các IP cố định đang thiết lập thủ công hiện có sẽ được đăng ký hàng loạt dưới dạng AutoDetected（3.2）, có thể phát sinh việc đồng loạt đạt ngưỡng xóa dẫn đến đồng loạt chuyển Cooldown・đồng loạt trả về pool. Vì vậy, trong giai đoạn đầu sẽ vận hành ngưỡng ngày tự động xóa AutoDetected bằng giá trị kéo dài ban đầu（khuyến nghị 90 ngày, tiền đề điều chỉnh theo đo thực tế）. Việc chuyển sang giá trị định thường（30 ngày）được thực hiện sau khi xác nhận số lượng chuyển Cooldown（quan sát bằng event log）đã hội tụ về mức giả định định thường（khoảng vài chục件/năm）. Ngưỡng là tham số ngoài（8.4）nên không cần thay đổi implementation khi chuyển đổi. Thông báo skip xóa trong giai đoạn chỉnh lý ban đầu（Phụ lục F#15）được xem là chỉ số tiến độ chỉnh lý ledger. Trong thời gian kéo dài ban đầu này, việc thu hồi AutoDetected IP thật sự không còn cần thiết cũng bị kéo dài theo cùng ngưỡng ngày, nhưng đây là đặc tính vận hành đánh đổi để ổn định ledger hóa（sẽ được giải quyết khi chuyển về giá trị định thường）, nên ghi tại mục này như đặc tính vận hành chứ không đưa vào “Giới hạn đã biết” của Phụ lục B.（thay thế v1.4. thay đổi yêu cầu=A-3）

Chức năng nâng cấp thiết bị hiện có lên trạng thái đã đăng ký không được triển khai trong dự án này（mở rộng trong tương lai）.

## 10.3 Vận hành khi thay đổi DHCP scope

Thay đổi exclusion range sẽ được Worker đồng bộ phản ánh ở lần chạy tiếp theo（tối đa sau 30 phút）. Khi thay đổi exclusion range hoặc thay CIDR（đặt record cũ IsActive=false + tạo mới）, cần thiết lập RangeChangePending=true cho segment đối tượng trước rồi mới thay đổi phía DHCP（flag đi trước. Nếu làm ngược lại, sẽ có tối đa 30 phút không được bảo vệ cho tới khi safety net của Worker đồng bộ phát hiện〔7.2〕— giới hạn đã biết）. Với thu hẹp・thay thế, trả false sau khi hoàn tất phản ánh đồng bộ; với mở rộng, trả false bằng phán định của Worker đồng bộ hoặc xác nhận thủ công sau khi điều kiện một vòng ledger hóa ARP（predicate gỡ ở 7.2）được thỏa mãn. Khi chạy thủ công Worker đồng bộ trong thay đổi khẩn cấp cũng phải tuân theo cùng vận hành flag. Nếu flag tồn đọng quá 24 giờ sẽ tự động thông báo（7.2）.（thay thế v1.4）

Sau khi thay đổi thiết lập scope phía server đại diện, phản ánh sang partner server bằng failover replication（Invoke-DhcpServerv4FailoverReplication）. Nếu nghi ngờ chưa phản ánh, thực hiện lại replication thủ công（thêm v1.2）.

Trong thời gian lỗi hoặc query thất bại của DHCP server đại diện（nkdc1/nkdc4）tiếp diễn, về nguyên tắc không thay đổi exclusion range hoặc scope thuộc server đó（vì thay đổi không được phản ánh vào IPAM/Segments, dẫn đến phán định cấp phát và phân phối thực tế bị lệch）. Nếu bắt buộc phải thay đổi trong lúc lỗi, cần thiết lập thủ công RangeChangePending cho segment đối tượng để dừng cấp phát rồi mới thực hiện（trong thời gian này, flag thủ công là lớp bảo vệ duy nhất）. Khi phục hồi lỗi, nếu replicate thay đổi đã thực hiện ở partner server về phía server đại diện, không được reverse replicate theo hướng đại diện → partner bằng định nghĩa cũ（rollback thay đổi）. Việc xác nhận tính nhất quán giữa cặp server tuân theo thủ tục Phụ lục C.1(3). Tạo mới ở v1.4.

Khi thay đổi khẩn cấp, quản trị viên chạy thủ công Worker đồng bộ.

Khi thêm DHCP scope mới, team network/infrastructure thêm thủ công record tương ứng vào list Segments và thiết lập DhcpScopeExists=true.

Cấm thay đổi CIDR. Khi cần thay đổi, thiết lập IsActive=false cho record cũ và tạo record mới bằng CIDR mới. Khi lập kế hoạch thu hẹp/trả lại dải IP cố định, cần kiểm tra trước rằng trong phạm vi dự kiến thu hẹp không còn IPAM entry Source=Requested và Cooldown nào（nếu còn thì chờ migration/hết hạn rồi mới thu hẹp）. Check này là mục checklist thủ công, không thể thay thế bằng kiểm soát kỹ thuật（giới hạn đã biết）.（thêm v1.4）

## 10.4 Vận hành khi lỗi・sự cố

Khi Worker cấp phát IP dừng: các đăng ký Pending sẽ bị tồn đọng; script giám sát phát hiện và thông báo.

Khi Worker thu thập ARP dừng: việc cập nhật LastSeenAt sẽ dừng. Script giám sát kiểm tra hằng ngày kết quả chạy lần trước trong Windows Event Log（IPAM-Worker）; nếu thất bại hoặc chưa chạy thì thông báo tới nkis-network. Ngoài ra, khi Worker tự động xóa khởi động, kiểm tra các thiết bị Failed trong ArpDeviceStatus và skip xóa đối với các segment tương ứng.

Phạm vi phát hiện của script giám sát（hằng ngày 07:00）: script giám sát phát hiện các mục sau và thông báo tới nkis-network（tất cả chỉ phát hiện・thông báo, không tự động khôi phục và không tự động gửi lại）. (1) Kết quả chạy lần trước của từng Worker bị thất bại hoặc chưa chạy（đã có）. (2) Tình trạng vượt chu kỳ chạy hoặc thường xuyên skip cycle（quy định vượt chu kỳ ở 8.4）. (3) Thiếu thông báo hoàn tất: các đăng ký có CompletionNotifiedAt chưa được thiết lập và Status cha đã ở trạng thái kết thúc（Assigned/PartiallyFailed）（thông báo như yêu cầu gửi lại thủ công. Vì \#2 không kích hoạt với Failed nên loại Failed khỏi tập trạng thái kết thúc. Đồng bộ với Phụ lục F#2）. (4) Tồn đọng record cha: các đăng ký mà Status cha vẫn là Pending quá 24 giờ kể từ khi tạo（phát hiện thống nhất các trường hợp thiếu tổng hợp・treo・đang pending kéo dài）. Quy trình bổ sung thủ công sau khi phát hiện (3)・(4)（gửi lại thông báo・thực hiện tổng hợp cha thủ công）sẽ được mô tả trong tài liệu quy trình vận hành（deliverable）. Quyền SharePoint của script giám sát chỉ là read-only（9.1）. Tạo mới ở v1.4.

Khi đăng ký DNS thất bại: rollback cả đăng ký IPAM và đưa đăng ký về Failed. Người đăng ký sẽ thực hiện đăng ký lại.

Khi lỗi truy cập SharePoint: Worker thực hiện retry; nếu tiếp tục thất bại thì thông báo cho quản trị viên.

Việc dừng chính Azure VM sẽ được phát hiện bằng heartbeat alert của Azure Monitor và thông báo tới nkis-network（vì script giám sát chạy trên VM không thể phát hiện việc chính VM đó bị dừng. Bổ sung v1.1）.

Việc xử lý các case Failed là best effort（không có SLA）. Với người đăng ký, hướng dẫn hành động tiếp theo bằng message ở mục 8.5.

Toàn bộ inquiry từ user và báo cáo đăng ký sai đều tiếp nhận qua IT Portal hiện có. Không tạo Teams channel riêng cho hệ thống này.

Vận hành list ArpDeviceStatus: lưu SharePoint view có filter CurrentStatus=Failed để team luôn nắm được các thiết bị đang bị sự cố.

## 10.5 Cấu hình backup

Máy chủ DHCP（4 máy on-premise）: tuân theo cơ chế backup server hiện có. Không thiết kế bổ sung trong dự án này.

Server IPAM+Worker（Azure VM）: backup hằng ngày bằng Azure Backup MARS agent.

Đối tượng backup: System State（bao gồm database IPAM WID）, toàn bộ data disk（script Worker・cấu hình・log）.

Retention: hằng ngày 30 ngày / hằng tuần 13 tuần / hằng tháng 12 tháng.

Recovery Services vault được tạo riêng cho hệ thống này.

SharePoint list: xử lý bằng chức năng chuẩn của M365. Version history（bật ở từng list）・Recycle bin（93 ngày）.

Không triển khai backup bên thứ ba bổ sung.

Bên vendor ngoài sẽ bàn giao 1 bộ tài liệu quy trình khôi phục như deliverable.

Sau khi restore, thực hiện kiểm tra tính nhất quán 3 bên giữa IPAM・SharePoint・DNS và resync（vì nếu chỉ IPAM quay về snapshot quá khứ thì có nguy cơ cấp phát trùng lại. Quy trình này được đưa vào tài liệu quy trình khôi phục. Bổ sung v1.1）.

## 10.6 Bảo trì master

Việc cập nhật Regions, Segments（record có DhcpScopeExists=false）, OfficeLocationMap do 3 thành viên team network/infrastructure thực hiện bằng cách chỉnh sửa trực tiếp SharePoint list. Khi chỉnh sửa trực tiếp Segments, cần chú ý lỗi network address và nhầm lẫn định dạng CIDR（chỉ kiểm tra thủ công, không có validation tự động）.

Cập nhật khi mở mới・đóng cơ sở sẽ được thực hiện đồng thời như một phần của công việc xây dựng network.

Việc cập nhật map của OfficeLocationMap được thực hiện mỗi khi có email thông báo MissLog làm trigger. Thông báo MissLog chỉ áp dụng cho trường hợp OfficeLocation không rỗng nhưng không match（giá trị rỗng chỉ ghi log, không thuộc đối tượng thông báo ngay. 3.1・Phụ lục F#8）.（bổ sung v1.4）

ArpDeviceStatus（thêm・loại bỏ thiết bị thu thập・thay đổi TargetSegments）cũng được duy trì bằng chỉnh sửa trực tiếp bởi team network/infrastructure. Khi mở cơ sở mới hoặc replace thiết bị, thực hiện đồng thời như một phần của công việc xây dựng network（bổ sung v1.1）. Khi thêm dòng thiết bị, bắt buộc nhập DeviceType・MerakiNetworkId（thiết bị Meraki）・MerakiOrgId（dùng cho ledger）（thiết bị chưa thiết lập DeviceType hoặc có giá trị ngoài định nghĩa sẽ bị skip thu thập. 7.3）. Dữ liệu initial bulk import sử dụng lại danh sách thiết bị là deliverable của Phụ lục C.6, và phân định trách nhiệm tuân theo Phụ lục G.（bổ sung v1.4）

Thủ tục ngừng sử dụng segment・tháo bỏ thiết bị thu thập（cố định thứ tự）: (1) Thiết lập RangeChangePending=true cho segment đối tượng và dừng cấp phát/đăng ký AutoDetected mới. (2) Kiểm tra không còn IPAM entry Source=Requested hoặc Cooldown trong phạm vi dự kiến thu hẹp/trả lại. (3) Sau khi hoàn tất migration hoặc xóa thủ công cần thiết, cập nhật Segments（IsActive=false hoặc tạo record mới）và ArpDeviceStatus.TargetSegments. (4) Chạy Worker đồng bộ segment hoặc chờ lần chạy kế tiếp, xác nhận trạng thái ổn định rồi gỡ RangeChangePending nếu cần.

Khi thêm record vào MissLog, Power Automate sẽ gửi email thông báo ngay cho team network/infrastructure.

Thủ tục cụ thể của master maintenance sẽ được mô tả trong tài liệu quy trình vận hành nội bộ（deliverable của vendor ngoài）.

Thủ tục khôi phục custom field của IPAM sẽ được đưa vào tài liệu quy trình vận hành（deliverable của vendor ngoài）dưới dạng script khôi phục.

## 10.7 Xử lý thủ công bởi bộ phận IT（tạo mới v1.2）

Việc xóa thủ công bởi bộ phận IT（do đăng ký sai・migration, v.v.）sẽ xử lý theo cùng state transition với tự động xóa. Cụ thể thực hiện 4 điểm sau.（thay thế v1.4. Đây là việc chuyển các số thứ tự (1)〜(4) trong phần thân thành bullet, nội dung không thay đổi）【(g)-3】

Xóa DNS record（trường hợp đã đăng ký hostname）.

Chuyển IPAM entry sang Source=Cooldown（giữ 30 ngày. Áp dụng thống nhất cả với xóa thủ công）. Khi chuyển, thêm giá trị Cooldown trong khi vẫn giữ nguyên giá trị Source gốc（multi-value. Không xóa hoặc thay thế giá trị gốc — dùng để phán định nguồn gốc Requested khi khôi phục〔Phụ lục F#14〕）. Đồng thời thiết lập CooldownStartedAt（6.8）.（thêm v1.4）

Thiết lập IPRequestItems.Status=Archived và ghi vào cột ErrorMessage rằng đây là xử lý thủ công cùng với số ticket IT Portal.

Cập nhật Status của record cha khi toàn bộ dòng chi tiết đã Archived.

Thủ tục sẽ được mô tả trong tài liệu quy trình vận hành dưới dạng checklist. Khi khôi phục thủ công IP đang trong Cooldown, phải tuân theo bản chuẩn khôi phục ở 7.4（※ ghi chú cooldown sau xóa. Liệt kê đầy đủ các field cần clear/giữ）.（thêm v1.4）

# 11. Tóm tắt các mục đã xác định

Chương này là tóm tắt các mục đã xác định tại thời điểm review v1.1. Các thay đổi phát triển thêm do sửa đổi v1.4 lấy nội dung phần thân của từng section（đặc biệt là 7.4・Phụ lục B）làm bản chuẩn.（bổ sung v1.4）

Phạm vi đối tượng cấp phát: toàn bộ thiết bị IT（server・printer・thiết bị NW・PC・khác）.

Hostname: nhập tùy chọn. Khi không nhập thì skip đăng ký DNS.

UI cascade: cấu hình 3 cấp Khu vực（tỉnh/thành hoặc quốc gia）→ Cơ sở → Segment.

Luồng phê duyệt: không có（xử lý tự động ngay sau khi đăng ký）.

Chức năng xóa: không triển khai cho user. Xử lý thủ công qua IT Portal.

Ngày dự kiến kết thúc: bãi bỏ（toàn bộ đăng ký được xem là sử dụng lâu dài）.

Quy tắc đặt tên hostname: ^(NKSV\|NKNODE\|PCD\|PCM\|PCS\|PRT)\[0-9\]{1,6}\$（validate sau khi chuyển sang chữ hoa, tối đa 12 ký tự）. Việc lưu vào SharePoint và đăng ký DNS đều thống nhất dùng giá trị đã chuẩn hóa sang chữ hoa（xác định ở v1.3）.

Source of Truth: địa chỉ IP là Windows IPAM, định nghĩa segment là list Segments.

Cấu hình triển khai: đặt IPAM+Worker chung trên cùng Azure VM. Liên kết với DHCP/DNS/thiết bị NW on-premise qua VPN/ExpressRoute.

Backup: backup Azure VM hằng ngày bằng Azure Backup（MARS）, SharePoint xử lý bằng chức năng chuẩn.

Master maintenance: 3 thành viên team network/infrastructure chỉnh sửa trực tiếp SharePoint.

Đầu mối inquiry: thống nhất qua IT Portal hiện có.

Xử lý Failed: best effort（không có SLA）.

Phương thức thông báo xóa: áp dụng phương án B（Worker → cập nhật NotificationStage của IPRequestItems（chi tiết）→ trigger Power Automate. Cùng một đăng ký・cùng một giai đoạn sẽ được tổng hợp và gửi 1 email）.

Safety thu thập ARP: pattern β theo đơn vị thiết bị（quản lý ArpDeviceStatus・phát hiện thất bại liên tục 72h・skip xóa）.

Triển khai Cooldown: giữ trong IPAM với giá trị Source=Cooldown trong 30 ngày rồi xóa vật lý. Nếu phục hồi trong thời gian này thì xử lý là AutoDetected（nếu có nguồn gốc Requested thì thông báo tới nkis-network）.

Xử lý lỗi: cấm silent error・phát hiện 100% trùng IP khi đăng ký/cấp phát・giới hạn RetryCount theo đơn vị chi tiết là 3 lần・ngăn Worker khởi động nhiều instance.

Cách tính dải IP cố định（xác định ở v1.1）: host range của CIDR segment − dynamic pool（scope range − exclusion range）− reserved IP.

Phạm vi đăng ký ARP（xác định ở v1.1）: chỉ trong dải IP cố định（không đăng ký các IP phát hiện trong dynamic pool）.

Đường thông báo（xác định ở v1.1）: thông báo cho user dùng Power Automate, alert phát từ Worker gửi qua SMTP relay nội bộ.

Gateway dự phòng（xác định ở v1.1）: chỉ đăng ký 1 máy đại diện vào ArpDeviceStatus（chấp nhận việc dừng phát hiện ARP khi máy đại diện bị lỗi）.

# Phụ lục A. Thuật ngữ

| **Thuật ngữ** | **Mô tả** |
|----|----|
| IPAM | IP Address Management. Cơ chế thực hiện cấp phát・quản lý địa chỉ IP. Trong tài liệu này chỉ chức năng chuẩn của Windows Server. |
| Source of Truth | “Nguồn sự thật”. Hệ thống hoặc dữ liệu đóng vai trò nguồn thông tin chính đáng tin cậy nhất đối với một thông tin nào đó. |
| Requested | Một trong các giá trị của field Source trong IPAM. Biểu thị IP được đăng ký thông qua đăng ký/yêu cầu. |
| AutoDetected | Một trong các giá trị của field Source trong IPAM. Biểu thị IP được tự động phát hiện・đăng ký bằng thu thập ARP. |
| LastSeenAt | Custom field của IPAM. Ngày giờ phản hồi ARP cuối cùng. |
| Thời gian Cooldown | Cách vận hành giữ lại IP đã bị xóa trong một khoảng thời gian nhất định thay vì trả ngay về pool IP trống. Trong tài liệu này là 30 ngày. Trong thời gian cooldown, IP được giữ trong IPAM với giá trị Source=Cooldown, và sau khi quá 30 ngày sẽ xóa vật lý（hiệu lực thực tế: giữ 30 ngày + 1 ngày xác nhận. Vì việc xóa vật lý do Worker tự động xóa thực hiện hằng ngày nên so với 30 ngày danh nghĩa, hiệu lực thực tế là 31 ngày. 7.4）. Nếu phát hiện phản hồi ARP trong thời gian này thì khôi phục với Source=AutoDetected（nếu có nguồn gốc Requested thì thông báo tới nkis-network）.（bổ sung v1.4） |
| SiteCode | Mã cơ sở. Dùng ở cấp trung gian của cascade 3 cấp. |
| OfficeLocationMap | SharePoint master list dùng để chuyển đổi giá trị OfficeLocation của Entra ID sang RegionCode/SiteCode. |
| MissLog | List dùng để ghi lại các giá trị OfficeLocation không match với OfficeLocationMap. Tên list là OfficeLocationMissLog. |
| MARS agent | Microsoft Azure Recovery Services agent. Dùng trong Azure Backup để backup file và System State của on-premise/VM. |
| ArpDeviceStatus | List quản lý trạng thái thiết bị thu thập ARP. Lưu số lần thất bại liên tiếp theo từng thiết bị và các segment mà thiết bị phụ trách. |
| Dynamic pool | Phạm vi mà DHCP phân phối động（scope range − exclusion range）. Dải IP cố định là phần bù của phạm vi này（sau khi trừ các IP reserved như network/broadcast/gateway）. |
| SkippedDays | Số ngày tích lũy mà đánh giá tự động xóa bị skip（theo đơn vị segment）. Đây là hạng mục hiệu chỉnh dùng để trừ khoảng thời gian đường thu thập không hợp lệ khỏi thời gian gia hạn khi tính số ngày đã trôi qua cho gia hạn xóa và hết hạn Cooldown. Khoảng thời gian quan sát ARP bị suppress sẽ không tiêu thụ thời gian gia hạn xóa（6.3・7.4）. Tạo mới ở v1.4 |
| RangeChangePending | Cờ theo đơn vị segment biểu thị trạng thái thay đổi dải IP cố định（thay đổi exclusion range・thay CIDR）đã được thực hiện phía DHCP nhưng việc phản ánh vào IPAM（và ledger hóa ARP khi mở rộng）chưa hoàn tất. Trong thời gian true, hệ thống sẽ hạn chế cấp phát mới cho segment đó, giữ đăng ký AutoDetected mới và thông báo phát hiện tồn đọng（6.3・7.1・7.2・7.3・10.3）. Tạo mới ở v1.4 |

# Phụ lục B. Tóm tắt policy

## Policy đăng ký・xóa IP

IP thông qua đăng ký được đăng ký với Source=Requested. Khi có nhập hostname thì đăng ký bản ghi A + PTR vào DNS.

Trong các IP phát hiện bằng ARP, chỉ các IP nằm trong dải IP cố định mới được đăng ký với Source=AutoDetected và không đăng ký vào DNS. Các IP phát hiện trong dynamic pool sẽ không được đăng ký.

Source=AutoDetected và LastSeenAt từ 1 tháng trở lên trước đó → xóa（chuyển sang Cooldown 30 ngày）.

Source=Requested sẽ cập nhật NotificationStage theo từng giai đoạn theo đơn vị chi tiết（IPRequestItems）（3 tháng: người đăng ký, 6 tháng: người đăng ký + Manager, 12 tháng: người đăng ký + Manager. Cùng một đăng ký・cùng một giai đoạn sẽ được tổng hợp thành 1 email）, sau đó ở mốc 12 tháng sẽ xóa IPAM+DNS và đặt Status chi tiết = Archived

IP đã bị xóa được giữ trong IPAM trong 30 ngày với Source=Cooldown. Sau khi quá 30 ngày sẽ xóa vật lý（trả về pool trống. Hiệu lực thực tế: giữ 30 ngày + 1 ngày xác nhận = thực tế 31 ngày. Sub-flow hết hạn Cooldown ở 7.4）. Nếu phát hiện phản hồi ARP trong thời gian này thì khôi phục với Source=AutoDetected（nếu có nguồn gốc Requested thì thông báo tới nkis-network）.（bổ sung v1.4）

Thời gian gia hạn xóa（1 tháng/3 tháng/6 tháng/12 tháng và Cooldown 30 ngày）được tính theo số ngày mà đường thu thập của segment tương ứng ở trạng thái hợp lệ. Khoảng thời gian quan sát ARP bị skip sẽ không tiêu thụ thời gian gia hạn（hiệu chỉnh bằng SkippedDays）.

## Policy đăng ký DNS

Zone đăng ký: ad.nkc.co.jp（DNS tích hợp AD）.

Cấu trúc FQDN: \<hostname\>.ad.nkc.co.jp.

Khi tạo record A, tự động tạo cả PTR reverse lookup bằng option -CreatePtr.

TTL: 3600 giây（thống nhất trong nội bộ công ty）.

Đối tượng: chỉ các IP có Source=Requested và có nhập hostname.

## Policy thao tác người dùng

Đăng ký: có thể thực hiện bất cứ lúc nào từ Power Apps. Cấp phát tự động ngay lập tức.

Thay đổi・xóa đăng ký: yêu cầu thủ công tới bộ phận IT thông qua IT Portal.

Giữ trước IP khi migration server: bộ phận IT thực hiện thủ công thông qua IT Portal.

Thay đổi hostname・chuyển đổi DNS: công việc thủ công của bộ phận IT（ngoài phạm vi hệ thống này）.

## Policy xử lý lỗi

Cấm silent error: mọi exception bắt buộc phải được ghi log và đi tới luồng thông báo tương ứng（người đăng ký hoặc nkis-network）.

- 登録・払い出し時のIP重複は100%検知：IPAM登録・払い出し・ARP検出の3経路で登録重複チェック、検知時は即時nkis-networkへ通知。運用中のIP競合疑い（Source=RequestedのIPで登録済みと異なるMACを検出）はMAC上書きと同時にnkis-networkへ通知する。

- RetryCount上限3回：上限到達でStatus=Failed確定＋nkis-networkへエスカレーション通知。

- Worker多重起動防止：ミューテックスまたはロックファイル方式を実装要件に明記。

- ARP収集セーフティ：機器単位パターンβ採用。72時間連続失敗でFailed遷移通知・Failed機器担当セグメントの自動削除スキップ。

※ 05 E区分の確定文言10件へ差替え。旧一覧10項目全体を見え消しで包み、新10件を確定文として置く。 ※ 依頼者確定：E①は「削除の実害は防止される」へ復元（意味変質の是正）。12ヶ月境界の限定句は付さない。 ※ 依頼者確定：旧項目8後段の創作文（監視スクリプト停止を#20で検知）は単純削除、どこにも書かない。 ※ 依頼者確定：旧項目10（初期稼働閾値延長のトレードオフ）は当一覧から削除し、10.2本文へ参照1文として残す（後掲）。

## 既知の制約（v1.4新設）

外部発注前レビュー（3-1／3-2／3-3）および複合故障シナリオ（CC-1〜CC-8）で確認された、本設計が仕様として受容する制約を一覧化する。いずれも影響が限定的または運用・監視で回復可能と判断したものである（詳細は該当節）。（v1.4新設）

1.  **収集経路の非保護窓**：ARP収集機器の障害検知（72時間連続失敗）が成立するまでの間、当該セグメントは削除スキップの保護外である。この窓で日数境界（90/180/365日）を跨いだ個体には、リマインダの誤送信が最大1回生じ得る（削除の実害はSkippedDays補正・緩衝・Cooldownで防止される）。

2.  **物理削除後の再出現IP**：廃止セグメントで物理削除後に再出現したIPは、IsActive=falseの間は台帳化されない。対策は廃止手順（10.6）の遵守であり、回収経路はIsActive=true復帰時の次ARPサイクルでの自己回復のみである。

3.  **Error滞留中の段階跨ぎ**：NotificationStage=Errorが日数境界を跨いで滞留した場合、復帰時の段階通知が最大1段階欠落し得る（12ヶ月削除通知は次段階遷移のクリアにより保証される）。

4.  **人手フラグ先行前の窓**：範囲変更でRangeChangePendingの先行設定を怠った場合、同期Workerのセーフティネット検知までの最大30分間は払い出し抑制が効かない。

5.  **代表サーバ障害中の変更**：障害中にパートナーサーバ側で行ったスコープ変更は、運用規定（10.3）でのみ保護され、技術的には検知されない。

6.  **走査開始スナップショットの1夜窓**：自動削除の除外判定は走査開始時点の状態で確定し、走査中の機器状態変化は翌日の実行から反映される。

7.  **SharePoint障害中の許容再送**：SharePoint書込障害の継続中は、同一段階の通知が複数回届き得る（送信済み記帳が成立した明細は再送されない・有界）。

8.  **完了通知の欠落回復**：通知フローの最終失敗による完了通知の欠落は、自動再送せず、監視スクリプトによる24時間以内の検知と手動再送で回復する。

9.  **縮小前チェックの非代替性**：固定IP範囲の縮小前のRequested/Cooldown残存確認（10.3）は人手チェックであり、技術制御では代替できない。

10. **Cooldownの実効期間**：Cooldownの物理削除は「30日保持＋確認1日」で実行される（公称30日に対し実効31日）。

11. **廃止セグメントの#15恒常発報とSkippedDays累積**：廃止セグメント（10.6-1の手順で機器行を削除したセグメント）は恒久的に未カバー判定となり、自動削除スキップ通知（付録F#15）が日次で発報し続け、SkippedDays／LastSkipDateへの加算も継続する。10.6-1の安全な廃止手順（残存IP棚卸し・処置後に撤去、最終的にレコード・レンジを手動削除）を最後まで遵守した場合、当該セグメントは走査対象から外れ#15も停止する。手順を(5)まで完遂せずIsActive=falseのまま滞留させた場合、#15発報とSkippedDays累積が継続する。手順未遵守で残存IPがある場合、当該IPは削除保護され続ける。（10.6-1・7.4）

12. **SkippedDaysの生涯累積**：SkippedDays補正はセグメント生涯にわたる累積であり、リセットされない。観測抑止が解消した後に登場した新規IPに対しても、過去の累積日数分だけ削除・リマインダ猶予が延伸する（方向は安全側＝早すぎる削除は起きない）。長期運用では公称値（1ヶ月／3ヶ月／6ヶ月／12ヶ月）から乖離し得る。（6.3・7.4・10.6/11.3の運用リセット判断）

13. **復帰部分失敗直後の恒久沈黙**：復帰処理の部分失敗直後に満了サブフローの条件(3)が恒久不成立となるCooldown残骸は、検知網の外で滞留し得る（方向は安全側＝誤削除は起きない）。発生確率は極小であり、10.7の手動棚卸しで回収する。（7.4満了サブフロー・7.3(a)・10.7）（7.4・付録A）

# 付録C. 事前調査チェックリスト

## C.1 DHCPスコープの除外範囲設計の一貫性

「動的プール（スコープ範囲−除外範囲）内に固定IP設定機器が存在しないこと」および「固定IP範囲（セグメントCIDRのホスト範囲−動的プール−予約IP）に既存固定機器が収容されていること」を全DHCPスコープで確認する。全スコープの除外範囲一覧を成果物として提出すること。全スコープの「除外範囲一覧」を成果物として提出すること。

（3）ペア間のスコープ定義整合（範囲・除外範囲）を全件確認・是正すること。検出済み不一致1件（奉賢工場172.31.140.0のEndRange：nkdc4=.219／nkdc5=.229）は正値を確定のうえ是正し、結果を本項の成果物に含めること（v1.2追加）。

## C.2 Meraki Dashboard APIのレート制限

全MX機器を1回のARP収集サイクル（1〜3時間）内でスキャンできるか確認する。Meraki組織数/ネットワーク数/MX台数の一覧＋既存API利用の有無を提出すること。

## C.3 海外DHCPサーバへの疎通確認

Azure VM → 海外オンプレDHCPサーバ2台の通信が成立するか確認する。疎通確認結果および必要なFW穴開け依頼を提出すること。

## C.4 Power Automateの月間実行数がE5範囲内で収まるか

本システム用のPower Automateフローが、E5ライセンスのPower Platformリクエスト制限内で運用できるか確認する。専用サービスアカウントの発行可否＋テナントレベル制限の有無を提出すること。

## C.5 SharePointバージョン履歴保持期間が監査要件を満たすか

IPRequests等に対して社内規定・法規制で求められる保存期間を満たせるか確認する。必要保管期間＋現行設定で足りるか否か＋不足なら追加設計要否を提出すること。

## C.6 ARP収集対象機器へのSNMP到達性・機器側設定（v1.1追加）

Azure VM（Worker）から全ARP収集対象機器へのSNMP（UDP/161）到達性、および機器側の許可設定（SNMP ACL/コミュニティ/SNMPv3ユーザ）の投入計画を確認する。対象機器一覧（ベンダ別台数・担当セグメント）を成果物として提出すること。機器側の設定投入は発注元側作業とする。機器一覧の項目には、各機器のDeviceType（CiscoIOS/FortiGate/YamahaRTX/MerakiMX）、およびMeraki機器のMerakiOrgId/MerakiNetworkIdを含める（ArpDeviceStatusの初期投入データとして流用する。6.9・10.6）。（v1.4追加）

# 付録D. 論点判断一覧（v1.0反映済み）

v1.0で反映した全18件の論点判断を一覧化する。

| **\#** | **論点** | **判断** |
|----|----|----|
| 1 | A-3-1 命名規則違反Failedの発生経路 | Worker側の分類を削除（Power Apps側バリデーションを信頼） |
| 2 | A-4-1 IPAMロールバック失敗時の扱い | Status=Failed・ErrorMessage詳細記録・nkis-networkへ緊急アラート（手動対応） |
| 3 | A-6-1 Graph APIリトライ失敗後の処理 | IPAMロールバック→Status=Pending→次サイクル再処理。RetryCount上限3でFailed確定+nkis-network通知 |
| 4 | A-10-1 Manager/UPN取得失敗通知のダイジェスト化 | 即時通知継続（ダイジェスト化なし） |
| 5 | A-5-1 Worker死活監視 | 監視スクリプトを1日1回実行、前回実行結果チェック、失敗/未実行時はnkis-networkへ通知 |
| 6 | O-6-1 Worker多重起動防止 | ミューテックスまたはロックファイル方式を実装要件に明記 |
| 7 | B-2-1 空きIP閾値の境界定義 | 残り20件以下で発報 |
| 8 | B-3-1 自動削除経過月の境界定義 | 日数ベース（30/90/180/365日）・JST深夜実行基準 |
| 9 | B-6-1 同一IP異MAC検出時のマージロジック | 最新タイムスタンプ優先でMAC上書き・通知なし |
| 10 | O-1-1 Segmentsリスト直接編集バリデーション | 人手確認のみ（ネットワークアドレス誤り・CIDR形式混同に注意喚起を運用手順書に記載） |
| 11 | O-2-1 IPAMカスタムフィールド復旧手順 | 運用手順書（外部発注先成果物）に復旧スクリプトとして含める |
| 12 | O-3-1 DHCPスコープ⇔Segments突合監査 | セグメント同期Worker実行時に突合チェック追加、漏れ検知時はnkis-networkへ通知 |
| 13 | O-4-1 CIDR変更時の整合性ずれ対応 | 運用ルールで禁止：変更不可・必要時はレコード新規作成+旧IsActive=false |
| 14 | A-12-1 AutoDetected重複状態での申請運用ガイド | 払い出し完了通知メール本文に「通知された新IPに手動設定変更」を明記（10.1節強化） |
| 15 | O-8-1 ユーザ単位の申請ガバナンス | 初期実装なし（空きIP閾値アラートで間接検知。問題化したら後追い） |
| 16 | I-10 自動削除時のIPRequests Status遷移 | IPRequests.StatusにArchived値を追加。自動削除実施時に設定（履歴保持） |
| 17 | I-11 クールダウン実装方式 | 案B継続（30日）＋IPAMにSource=Cooldown値追加。30日経過後に物理削除 |
| 18 | I-13 DhcpScopeExists=falseの閾値アラート対象 | 全セグメント走査に変更（Segments全件・IPAM使用数照会・アラート判定を全セグメント対象化） |

※ v1.1での変更：A-3-1はWorker側のホスト名再検証を復活（防御的二重チェック）、B-6-1はSource=Requestedの異MAC検出時に競合疑い通知を追加、I-10は段階管理をIPRequestItems（明細）単位へ変更。判断経緯の記録として表本体はv1.0時点の記載のまま保持する。

# 付録E. 実装規約（セキュリティ・コーディング）（v1.1新設）

- 実行アカウント：gMSA不可の場合は通常サービスアカウントとし、対話型ログオン拒否・最小権限・タスクスケジューラ登録時以外のパスワード保存禁止を条件とする。

- 秘密情報の保管：SNMP資格情報、Meraki APIキー、Graph API証明書秘密鍵、SMTP設定値のスクリプト・設定ファイルへの平文記載を禁止する。PowerShellはSecretManagement＋SecretStoreまたはDPAPI（Export-Clixml）、PythonはDPAPI（win32crypt）または資格情報マネージャを使用し、実行アカウントに紐付く保護とする。

- SNMP：SNMPv2cを標準とする。コミュニティ名は全機器共通（全社共通1系統）とし、例外機器が生じた場合のみDeviceIdをキーにSecretStoreへ個別登録する。機器側ACLは別設計書の管理範囲（作業者=発注元）のため本書には記載しない（v1.3改訂）。

- コーディング：例外の握り潰しを禁止する（全例外でログ記録＋通知経路への到達を保証）。PowerShellはWindows PowerShell 5.1（IPAMモジュール互換）でPSScriptAnalyzer既定ルールに適合させる。PythonはPython 3.11以上、venv＋requirements.txtで依存を固定する。戻り値・終了コードで成否を判定可能とすること。

- 通知抑制状態のローカル保持：通知の重複抑制に用いる状態（例：代表DHCPサーバ照会失敗の1日1回抑制記録）は、SharePointリストへ列追加せずWorkerローカルに保持してよい（喪失時は再通知となるのみで安全側）。ただし削除判定・除外判定に影響する状態のローカル保持は禁止する（本文8.4と整合）。（v1.4追加）

- 証明書・キー管理：Graph API証明書の有効期限監視（期限60日前にnkis-networkへ通知）と更新手順、Meraki APIキーのローテーション手順を運用手順書に定義する。

# 付録F. 通知一覧（v1.1新設）

| **\#** | **イベント** | **宛先** | **送信経路・契機** |
|----|----|----|----|
| 1 | 申請受付 | 申請者 | Power Automate（親レコード作成トリガ） |
| 2 | 払い出し完了 | 申請者 | Power Automate（親Status=Assigned/PartiallyFailed）。送信は7.4の通知フロー共通規約に準拠し、CompletionNotifiedAt未設定を条件に送信・送信成功確認後に更新（v1.4契機明確化） |
| 3 | 払い出し失敗 | 申請者 | Power Automate（明細Status=Failed。文面は8.5）。FailureNotifiedAt未設定を条件に送信・送信成功確認後に更新。フロー並列度1（v1.4契機明確化） |
| 4 | 3ヶ月リマインダ | 申請者 | Power Automate（明細NotificationStage。集約送信・並列度1・NotificationSentAtガード。7.4） |
| 5 | 6ヶ月リマインダ | 申請者+Manager | 同上 |
| 6 | 12ヶ月削除通知 | 申請者+Manager | 同上 |
| 7 | 通知異常（UPN/Manager取得失敗等） | nkis-network | Power Automate（NotificationStage=Error）。独立トリガフローとせず、#4〜#6の送信フロー自身がエラー捕捉時にError書込と本通知を実施する（7.4・v1.3確定） |
| 8 | MissLog検知 | nkis-network | Power Automate（MissLog作成トリガ）。OfficeLocation非空の未マッチのみ（空値は記録のみ・通知なし。3.1・10.6）（v1.4契機明確化） |
| 9 | 空きIP閾値（20件以下） | nkis-network | セグメント同期Worker→SMTPリレー |
| 10 | DHCP⇔Segments突合漏れ | nkis-network | セグメント同期Worker→SMTPリレー |
| 11 | ARPカバレッジ漏れ | nkis-network | セグメント同期Worker→SMTPリレー（CoverageNotifiedAtで1日1回抑制。7.2） |
| 12 | ARP機器Failed遷移/Failedリマインダ | nkis-network | ARP収集Worker→SMTPリレー |
| 13 | IP競合疑い（Requested異MAC） | nkis-network | ARP収集Worker→SMTPリレー |
| 14 | Cooldown中復帰（Requested由来） | nkis-network | ARP収集Worker→SMTPリレー（復帰処理はIPAM反映スクリプトが実施。7.3・7.4） |
| 15 | 削除スキップ（日次） | nkis-network | 自動削除Worker→SMTPリレー。Failed機器由来・未カバー由来・レンジ非所属由来を事由別に記載し、スキップ継続日数（SkippedDays）を付す（7.4・8.5）（v1.4契機明確化） |
| 16 | IPAMロールバック失敗（緊急） | nkis-network | IP払い出しWorker→SMTPリレー |
| 17 | RetryCount上限到達 | nkis-network | IP払い出しWorker→SMTPリレー |
| 18 | Processing滞留回収 | nkis-network | IP払い出しWorker→SMTPリレー |
| 19 | DNS環境不備（逆引きゾーン欠落等） | nkis-network | IP払い出しWorker→SMTPリレー |
| 20 | Worker死活監視失敗・未実行 | nkis-network | 監視スクリプト→SMTPリレー。完了通知欠落・親Status=Pending滞留（24時間超）の検知通知も本経路で送信する（10.4）（v1.4契機拡張） |
| 21 | VMハートビート停止 | nkis-network | Azure Monitor |

※ ユーザ向け通知（#1〜6）の文面テンプレートは別途ドラフトレビューで確定する（13章）。SharePointトリガは列単位の変更検知を持たないため、各フローはトリガ条件＋送信済み判定（NotificationSentAt等）で多重発火を防止し、NotificationStage連動フローは並列度1で構成すること。

# 付録G. 責任分界表（RACI）（v1.3新設）

11章「貴社」を「発注元（NKC）」に全置換したことに伴い、契約前提となる主要作業の主体を一覧化する（Q37確定）。11章・13章・付録Cの全作業を対象とし、詳細な期限区分は各該当節を参照。

| **作業項目** | **主体** | **備考** |
|----|----|----|
| サブスクリプション・VNet/サブネット・NSG・命名規則の準備 | 発注元 | 課金・ネットワーク境界はガバナンス事項のため外部委譲しない（Q39） |
| Azure VM作成〜OS設定・IPAM有効化・スケジューラ登録 | 受注側 | 11.1工数どおり（Q39） |
| 検証用SharePointサイト・検証用DHCPスコープ・DNS検証用サブゾーンの用意 | 発注元 | 専用検証環境は新設しない（Q40） |
| 受注側要員への期限付きアカウント付与・既設VPN接続 | 発注元 | Q40 |
| IPAM管理用GPO作成 | 発注元 | 受注側は定義書・手順書・検証を提供（Q41） |
| Entra IDアプリ登録の管理者同意 | 発注元 | セキュリティ部門の既存承認プロセスに載せる（Q41） |
| ArpDeviceStatus初期データの一覧作成（機器一覧。DeviceType/MerakiOrgId/MerakiNetworkIdを含む） | 発注元 | C.6成果物の機器一覧を流用（Q44・10.6）。DeviceType・MerakiNetworkIdは収集の駆動キーのため一覧作成時に確定させる（6.9・7.3）（v1.4：既存「一覧作成」行に項目を追記。(g)-2） |
| ArpDeviceStatus初期データのSharePoint投入 | 受注側 | CSVツールを拡張して対応（+0.3人日目安。Q44） |
| Segmentsマスター初期投入作業 | 発注元 | 本工数に含まない（11.1既定） |
| 付録C事前調査（C.1〜C.6） | 発注元 | 契約締結前・Week2末までの期限別（Q43は保留） |
| WorkerサーバIPの社内SMTPリレー許可元登録 | 発注元 | 13章参照 |
| 対象NW機器へのSNMP許可設定（ACL/コミュニティ）の投入 | 発注元 | 付録C.6参照 |
| DHCPペア間スコープ定義不整合の是正 | 発注元 | 付録C.1参照 |
| gMSA利用可否の社内調整（KDSルートキー整備） | 発注元 | 13章参照 |
| Power Automate送信元メールボックスの確定 | 発注元 | 13章参照 |
| 本番移行の拠点段階公開判断・初期削除閾値の切替判断 | 発注元 | 段階的サービスイン・初期稼働期間の閾値運用の判断主体（10.2・11.2）。v1.4新設（要件変更＝A-3） |
