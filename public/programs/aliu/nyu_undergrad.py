from aliu import config
import os
import json


def get_grades(ignore=set()):
    with open(os.path.join(os.path.dirname(__file__), 'nyu-undergrad-transcript.json')) as transcript:
        return [{k: v
                 for k, v in course.items() if k not in ignore}
                for course in json.load(transcript)]


def set_grades(grades):
    with open(os.path.join(os.path.dirname(__file__), 'nyu-undergrad-transcript.json'), 'w') as transcript:
        json.dump(grades, transcript)


def sem_to_number(sem):
    if sem == 'ja':
        return 1
    if sem == 'sp':
        return 2
    if sem == 'su':
        return 3
    if sem == 'fa':
        return 4
    return False  # It's an enum, should only have one of those four values


def validate_course(course):
    def validate_key(key, validation):
        assert (key in course and validation(course[key]))

    validate_key('name', lambda name: isinstance(name, str))
    validate_key('grade', lambda grade: grade_to_number(grade) is not False)
    validate_key(
        'credits',
        lambda credits: credits <= 4 and credits >= 0 and isinstance(
            credits, int))
    validate_key('year', lambda year: isinstance(year, int) and year > 2000)
    validate_key('semester', lambda sem: sem in ['sp', 'fa', 'su', 'ja'])
    validate_key('subject', lambda subject: isinstance(subject, str))
    validate_key('school', lambda school: isinstance(school, str))


# add_grade("Special Topics: Applied Internet Technology", "A-", subject="CSCI-UA", credits=4, semester="sp2021")
def add_grade(name, grade, subject='core-ua', credits=4, semester=None):
    grade_data = get_grades()

    year = int(semester[2:])
    if year < 100:
        year += 2000

    data = {
        'name': name,
        'grade': grade.upper(),
        'credits': credits,
        'year': year,
        'semester': semester[0:2],
    }

    if isinstance(subject, str):
        data['subject'], data['school'] = subject.upper().split('-')

    validate_course(data)

    assert (data not in grade_data)
    grade_data.append(data)

    def course_to_key(course):
        return (course['year'], sem_to_number(course['semester']),
                course['name'])

    set_grades(sorted(grade_data, key=course_to_key))


def remove_grade(index):
    grades = get_grades()
    del grades[index]
    set_grades(grades)


def grade_to_number(grade_letter):
    if grade_letter == 'A':
        return 4
    if grade_letter == 'A-':
        return 3.666666
    if grade_letter == 'B+':
        return 3.333333
    if grade_letter == 'B':
        return 3
    if grade_letter == 'B-':
        return 2.666666
    if grade_letter == 'C+':
        return 2.333333
    if grade_letter == 'C':
        return 2
    if grade_letter == 'C-':
        return 1.666666
    if grade_letter == 'P':
        return -1
    if grade_letter == 'W':
        return -1
    return False  # Should not get here


def gpa():
    grade_data = get_grades()
    total = 0
    total_credits = 0
    for course in grade_data:
        grade = grade_to_number(course['grade'])
        credits = course['credits']
        if grade == -1:  # Grade shouldn't be counted
            continue
        else:
            total += grade * credits
            total_credits += credits
    if total_credits == 0:
        return 4.0
    return total / total_credits


def major_gpa(major='csci-ua'):
    major = major.upper()
    grade_data = get_grades()

    total = 0
    total_credits = 0
    for course in grade_data:
        if course['subject'] + '-' + course['school'] != major:
            continue

        grade = grade_to_number(course['grade'])
        credits = course['credits']
        if grade == -1:  # Grade shouldn't be counted
            continue
        else:
            total += grade * credits
            total_credits += credits
    if total_credits == 0:
        return 4.0
    return total / total_credits
