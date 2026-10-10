"""Seeds QA accounts and data for integration_test/app_test.dart (local backend only).

Run from TIIPE/backend:  venv/bin/python manage.py shell < /path/to/qa_seed.py
Remove with qa_clean.py. Never run against production."""
from decimal import Decimal
from django_tenants.utils import schema_context
from apps.users.models import CustomUser, UserProfile
with schema_context('novatrix'):
    from apps.novatrix_services.models import (TrainingCourse, CourseModule, Lesson, CourseEnrollment,
        LessonCompletion, AssignmentSubmission, ClientProject, ProjectDocument, ProjectUpdate, SupportTicket,
        CourseAnnouncement)
    def user(email, first, last):
        u = CustomUser.objects.create_user(email=email, password='Qa-Str0ng-pass!')
        UserProfile.objects.create(user=u, first_name=first, last_name=last, country='Nigeria', state_or_city='Lagos')
        return u
    ada = user('qa-app@example.com', 'Ada', 'Okafor')
    student = user('qa-app-student@example.com', 'Tunde', 'Bello')
    learn = TrainingCourse.objects.create(title='QA Product Analytics', slug='qa-app-course', duration_weeks=6,
        summary='Measure what matters in digital products.', target_audience='Product teams', price_amount=Decimal('0'))
    m = CourseModule.objects.create(course=learn, title='Week 1: Foundations', summary='Metrics that matter', is_published=True)
    l1 = Lesson.objects.create(module=m, title='Welcome to the course', content='## Welcome\n\nIn this course you will learn to:\n\n- Define **north-star metrics**\n- Build simple dashboards\n\n> Tip: keep a notebook of questions.', is_published=True, duration_minutes=10)
    l2 = Lesson.objects.create(module=m, title='Funnels in practice', kind='video', video_url='https://www.youtube.com/watch?v=dQw4w9WgXcQ', content='Watch the walkthrough, then try the exercise.', is_published=True, duration_minutes=18)
    l3 = Lesson.objects.create(module=m, title='Project: your first dashboard', kind='assignment', content='Build a one-page dashboard and share the link.', is_published=True)
    e = CourseEnrollment.objects.create(user=ada, course=learn)
    LessonCompletion.objects.create(enrollment=e, lesson=l1); e.recalculate_progress()
    CourseAnnouncement.objects.create(course=learn, title='Live Q&A on Friday', body='Join us at 4pm WAT with your questions.')
    teach = TrainingCourse.objects.create(title='QA Intro to Python', slug='qa-app-teach', duration_weeks=4,
        summary='Python basics for analysts.', target_audience='Beginners', price_amount=Decimal('0'))
    teach.facilitators.add(ada)
    tm = CourseModule.objects.create(course=teach, title='Week 1', is_published=True)
    tl = Lesson.objects.create(module=tm, title='Exercise: clean a CSV', kind='assignment', is_published=True)
    te = CourseEnrollment.objects.create(user=student, course=teach)
    AssignmentSubmission.objects.create(enrollment=te, lesson=tl, link_url='https://github.com/example/csv-cleaner', notes='Used pandas for the cleanup.')
    p = ClientProject.objects.create(title='QA School Portal', organization='QA Academy', status='testing',
        summary='A portal for parents and teachers.', start_date='2026-08-01', target_end_date='2026-12-15')
    p.members.add(ada)
    ProjectDocument.objects.create(project=p, title='QA Test plan', url='https://example.com/plan', is_client_visible=True)
    ProjectUpdate.objects.create(project=p, title='User testing started', body='Teachers begin testing on Monday.', is_client_visible=True)
    SupportTicket.objects.create(client_name='Ada', organization='QA Academy', email='qa-app@example.com',
        affected_system='Parent login', issue_description='Some parents cannot reset passwords.', urgency='high',
        submitted_by=ada, client_project=p)
    print('seeded')
