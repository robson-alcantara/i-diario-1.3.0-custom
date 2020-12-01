class PartialScoreRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :student_id,
                :school_calendar_step_id,
                :school_calendar_classroom_step_id,
                :school_calendar_year

  validates :unity_id,      presence: true
  validates :classroom_id,  presence: true
  validates :student_id, presence: true
  validates :school_calendar_step_id, presence: true, if: :should_validate_presence_of_school_calendar_step
  validates :school_calendar_classroom_step_id, presence: true, if: :should_validate_presence_of_classroom_school_calendar_step

  validate :must_have_daily_note_students

  def daily_note_students
    @daily_note_students ||= DailyNoteStudent.includes(:daily_note)
                                             .by_classroom_id(classroom_id)
                                             .by_student_id(student_id)
                                             .exclude_discipline_ids(exempted_disciplines)
                                             .by_test_date_between(step.start_at, step.end_at)
                                             .order_by_discipline_and_date
  end

  def step
    return unless school_calendar_step_id || school_calendar_classroom_step_id

    if classroom.calendar
      @step ||= SchoolCalendarClassroomStep.find(school_calendar_classroom_step_id)
    else
      @step ||= SchoolCalendarStep.find(school_calendar_step_id)
    end
  end

  def school_calendar
    if classroom.calendar
      step.school_calendar_classroom
    else
      step.school_calendar
    end
  end

  def student
    return unless student_id

    @student ||= Student.find(student_id)
  end

  def classroom
    return unless classroom_id

    @classroom ||= Classroom.find(classroom_id)
  end

  def unity
    return unless unity_id

    @unity ||= Unity.find(unity_id)
  end

  private

  def exempted_disciplines
    return [] unless step
    StudentEnrollmentExemptedDiscipline.
      by_student_enrollment(
        StudentEnrollment.by_student(student_id)
                     .by_date_range(step.start_at, step.end_at)
                     .joins(:exempted_disciplines)
                     .pluck(:id)
      ).
      by_step_number(step.to_number)
      .pluck(:discipline_id)
  end

  def must_have_daily_note_students
    return unless errors.blank?

    if daily_note_students.count == 0
      errors.add(:daily_note_students, :must_have_daily_note_students)
    end
  end

  def should_validate_presence_of_school_calendar_step
    school_calendar_classroom_step_id.blank?
  end

  def should_validate_presence_of_classroom_school_calendar_step
    school_calendar_step_id.blank?
  end
end
