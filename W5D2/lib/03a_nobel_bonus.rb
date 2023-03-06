# == Schema Information
#
# Table name: nobels
#
#  yr          :integer
#  subject     :string
#  winner      :string

require_relative './sqlzoo.rb'

def physics_no_chemistry
  # In which years was the Physics prize awarded, but no Chemistry prize?

  #find years where chem was not granted, see within this list if any year had phys grant
  execute(<<-SQL)
    SELECT
      yr
    FROM
      nobels
    GROUP BY
      yr
    HAVING
      count(case Subject when 'Chemistry' then 1 else null end) = 0 AND count(case Subject when 'Physics' then 1 else null end) > 0 
  SQL
end

#Find the list of years with a chem prize granted
#yr from nobels where subject = "chem"

# SELECT
# DISTINCT yr
# FROM
# nobels
# WHERE
# yr NOT IN 
# (
#   SELECT
#     DISTINCT yr
#   FROM
#     nobels
#   WHERE
#     subject = 'Chemistry'
# )
# AND
# subject = 'Physics'