"""Removes everything qa_seed.py created."""
from django_tenants.utils import schema_context
from apps.users.models import CustomUser
with schema_context('novatrix'):
    from apps.novatrix_services.models import TrainingCourse, CourseEnrollment, ClientProject, SupportTicket
    SupportTicket.objects.filter(organization='QA Academy').delete()
    ClientProject.objects.filter(organization='QA Academy').delete()
    CourseEnrollment.objects.filter(course__slug__in=['qa-app-course', 'qa-app-teach']).delete()
    TrainingCourse.objects.filter(slug__in=['qa-app-course', 'qa-app-teach']).delete()
    CustomUser.objects.filter(email__in=['qa-app@example.com', 'qa-app-student@example.com']).delete()
    print('clean:', CustomUser.objects.filter(email__startswith='qa-').count(), TrainingCourse.objects.filter(slug__startswith='qa-').count())
