/// Standalone CSS styles for HTML booklet printing and rendering
String buildBookletCss() {
  return '''
      @page {
        size: A4 portrait;
        margin: 18mm 15mm;
      }
      * {
        box-sizing: border-box;
      }
      body {
        margin: 0;
        padding: 0;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "PingFang SC", "Microsoft YaHei", sans-serif;
        color: #1e293b;
        background: #f8fafc;
        line-height: 1.6;
      }
      .page {
        background: #ffffff;
        max-width: 860px;
        margin: 20px auto;
        padding: 48px;
        box-shadow: 0 4px 20px rgba(0,0,0,0.06);
        border-radius: 8px;
        page-break-after: always;
      }
      @media print {
        body {
          background: #ffffff;
        }
        .page {
          margin: 0;
          padding: 0;
          box-shadow: none;
          border-radius: 0;
          max-width: 100%;
        }
      }
      .cover-page {
        display: flex;
        align-items: center;
        justify-content: center;
        min-height: 800px;
        text-align: center;
      }
      .cover-border {
        border: 2px solid #cbd5e1;
        padding: 60px 40px;
        width: 100%;
        border-radius: 6px;
      }
      .cover-subtitle {
        font-size: 13px;
        font-weight: 700;
        letter-spacing: 2px;
        color: #64748b;
        margin-bottom: 24px;
      }
      .cover-title {
        font-size: 44px;
        font-weight: 800;
        color: #0f172a;
        margin: 0 0 16px 0;
      }
      .cover-divider {
        font-size: 20px;
        color: #6366f1;
        margin: 20px 0;
      }
      .cover-edition {
        font-size: 18px;
        font-weight: 500;
        color: #475569;
        margin-bottom: 60px;
      }
      .cover-meta {
        font-size: 14px;
        color: #64748b;
        line-height: 1.8;
      }
      .section-heading {
        font-size: 24px;
        font-weight: 700;
        color: #0f172a;
        border-bottom: 2px solid #e2e8f0;
        padding-bottom: 12px;
        margin-top: 0;
        margin-bottom: 28px;
      }
      .sub-heading {
        font-size: 16px;
        font-weight: 700;
        color: #334155;
        margin: 24px 0 12px 0;
        border-left: 3px solid #6366f1;
        padding-left: 8px;
      }
      .toc-list {
        margin-top: 30px;
      }
      .toc-item {
        display: flex;
        align-items: baseline;
        margin-bottom: 16px;
        font-size: 16px;
      }
      .toc-title {
        font-weight: 600;
        color: #334155;
      }
      .toc-dots {
        flex: 1;
        border-bottom: 1px dotted #cbd5e1;
        margin: 0 12px;
      }
      .toc-page-num {
        font-weight: 700;
        color: #64748b;
      }
      .badge {
        display: inline-block;
        font-size: 12px;
        padding: 2px 8px;
        border-radius: 4px;
        background: #f1f5f9;
        color: #475569;
        font-weight: 500;
      }
      .badge-accent {
        background: #ede9fe;
        color: #6366f1;
      }
      .badge-fav {
        background: #fef3c7;
        color: #b45309;
      }
      .character-header {
        display: flex;
        gap: 24px;
        margin-bottom: 24px;
      }
      .character-avatar-wrap {
        width: 140px;
        height: 140px;
        flex-shrink: 0;
      }
      .character-avatar {
        width: 100%;
        height: 100%;
        object-fit: cover;
        border-radius: 8px;
        border: 1px solid #e2e8f0;
      }
      .character-avatar-placeholder {
        width: 100%;
        height: 100%;
        background: #f1f5f9;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 48px;
        color: #94a3b8;
        font-weight: bold;
      }
      .character-summary {
        flex: 1;
      }
      .character-name {
        margin: 0 0 8px 0;
        font-size: 26px;
        color: #0f172a;
      }
      .character-tags {
        display: flex;
        gap: 6px;
        margin-bottom: 12px;
        flex-wrap: wrap;
      }
      .character-brief {
        font-size: 14px;
        color: #475569;
        line-height: 1.6;
      }
      .stats-row {
        display: flex;
        align-items: center;
        gap: 24px;
        flex-wrap: wrap;
      }
      .radar-wrap {
        width: 280px;
        height: 280px;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      .stats-table-wrap {
        flex: 1;
        min-width: 220px;
      }
      .stats-table, .full-table {
        width: 100%;
        border-collapse: collapse;
        font-size: 13px;
      }
      .stats-table th, .stats-table td, .full-table th, .full-table td {
        padding: 8px 12px;
        border: 1px solid #e2e8f0;
        text-align: left;
      }
      .stats-table th, .full-table th {
        background: #f8fafc;
        color: #475569;
        font-weight: 600;
      }
      .timeline-item {
        display: flex;
        gap: 20px;
        margin-bottom: 20px;
      }
      .timeline-year {
        width: 90px;
        font-weight: 700;
        color: #6366f1;
        font-size: 15px;
        text-align: right;
      }
      .timeline-body {
        flex: 1;
        border-left: 2px solid #e2e8f0;
        padding-left: 16px;
      }
      .timeline-header {
        display: flex;
        gap: 8px;
        align-items: center;
        margin-bottom: 4px;
      }
      .timeline-title {
        font-weight: 700;
        font-size: 15px;
      }
      .timeline-stars {
        color: #f59e0b;
        font-size: 12px;
      }
      .timeline-desc {
        font-size: 14px;
        color: #475569;
      }
      .simple-timeline {
        padding-left: 20px;
        font-size: 13px;
        color: #334155;
      }
      .rel-chips {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }
      .rel-chip {
        background: #f8fafc;
        border: 1px solid #e2e8f0;
        padding: 6px 12px;
        border-radius: 6px;
        font-size: 13px;
      }
      .rel-badge {
        font-weight: 700;
        color: #6366f1;
      }
      .gallery-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(140px, 1fr));
        gap: 12px;
      }
      .gallery-item img {
        width: 100%;
        height: 140px;
        object-fit: cover;
        border-radius: 6px;
        border: 1px solid #e2e8f0;
      }
      .gallery-caption {
        font-size: 11px;
        color: #64748b;
        text-align: center;
        margin-top: 4px;
      }
      .wiki-link {
        color: #6366f1;
        background: #ede9fe;
        padding: 1px 4px;
        border-radius: 3px;
        font-weight: 600;
      }
      .groups-grid {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
        gap: 16px;
      }
      .group-card {
        border: 1px solid #e2e8f0;
        border-radius: 8px;
        padding: 16px;
        background: #fafafa;
      }
      .group-title {
        margin: 0 0 10px 0;
        font-size: 16px;
        color: #0f172a;
      }
      .text-muted {
        color: #94a3b8;
      }
    ''';
}
