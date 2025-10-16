import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../utils/time_formatter.dart';
import '../services/notice_service.dart';

class ProfessionalNoticeCard extends StatefulWidget {
  final Notice notice;
  final bool isDarkMode;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ProfessionalNoticeCard({
    super.key,
    required this.notice,
    required this.isDarkMode,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  State<ProfessionalNoticeCard> createState() => _ProfessionalNoticeCardState();
}

class _ProfessionalNoticeCardState extends State<ProfessionalNoticeCard> {
  bool _showDetailedTime = false;

  Color _getPriorityColor() {
    switch (widget.notice.priority) {
      case NoticePriority.high:
        return Colors.red;
      case NoticePriority.normal:
        return Colors.green;
      case NoticePriority.low:
        return Colors.orange;
    }
  }

  String _getPriorityText() {
    switch (widget.notice.priority) {
      case NoticePriority.high:
        return 'High';
      case NoticePriority.normal:
        return 'Normal';
      case NoticePriority.low:
        return 'Low';
    }
  }

  String _getCategoryText() {
    switch (widget.notice.category) {
      case NoticeCategory.exam:
        return 'Exam';
      case NoticeCategory.assignment:
        return 'Assignment';
      case NoticeCategory.event:
        return 'Event';
      case NoticeCategory.general:
        return 'General';
      case NoticeCategory.announcement:
        return 'Announcement';
      case NoticeCategory.academic:
        return 'Academic';
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.notice.category) {
      case NoticeCategory.exam:
        return Icons.quiz;
      case NoticeCategory.assignment:
        return Icons.assignment;
      case NoticeCategory.event:
        return Icons.event;
      case NoticeCategory.general:
        return Icons.info;
      case NoticeCategory.announcement:
        return Icons.campaign;
      case NoticeCategory.academic:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final cardColor = widget.isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final borderColor = widget.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!;
    

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Profile + Time + Menu
              Row(
                children: [
                  // Admin Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Admin Name and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.notice.authorName,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showDetailedTime = !_showDetailedTime;
                            });
                          },
                          child: Text(
                            _showDetailedTime 
                                ? TimeFormatter.formatPerfectTimestamp(widget.notice.createdAt)
                                : TimeFormatter.formatTimeAgo(widget.notice.createdAt),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Three-dot menu (only show if user is admin)
                  if (NoticeService.isUserAdmin())
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      ),
                      onSelected: (value) {
                        if (value == 'edit' && widget.onEdit != null) {
                          widget.onEdit!();
                        } else if (value == 'delete' && widget.onDelete != null) {
                          widget.onDelete!();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Title (Bold)
              Text(
                widget.notice.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Content
              Text(
                widget.notice.content,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 16),
              
              // Bottom Tags: Priority + Category + Date
              Row(
                children: [
                  // Priority Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPriorityColor().withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPriorityText(),
                          style: TextStyle(
                            color: _getPriorityColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(),
                          color: Colors.blue,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getCategoryText(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode 
                          ? Colors.grey[800] 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      TimeFormatter.formatDate(widget.notice.createdAt),
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
