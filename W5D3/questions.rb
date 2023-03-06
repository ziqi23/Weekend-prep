require "sqlite3"
require "singleton"

class QuestionsDatabase < SQLite3::Database
    include Singleton
    def initialize
        super('questions2.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class Questions

    attr_accessor :id, :title, :body, :associated_author_id

    def save
        if !self.id.nil?
            self.update
        else
            QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @associated_author_id)
                INSERT INTO
                    questions (title, body, associated_author_id)
                VALUES 
                    (?, ?, ?)
            SQL
        end
    end

    def update  
        QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @associated_author_id, @id)
            UPDATE
                questions 
            SET
                title = ?, body = ?, associated_author_id = ?
            WHERE
                id = ?
            SQL
    end


    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
        data.map { |datum| Questions.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            questions
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        Questions.new(data.first)
    end

    def self.find_by_associated_author_id(associated_author_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, associated_author_id)
        SELECT
            *
        FROM
            questions
        WHERE
            associated_author_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Questions.new(datum) } # someone may author many posts
    end

    def self.most_followed(n)
        QuestionFollows.most_followed_questions(n)
    end

    def self.most_liked(n)
        QuestionLikes.most_liked_questions(n)
    end

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @associated_author_id = options['associated_author_id']
    end

    def author
        Users.find_by_id(associated_author_id)
    end

    def replies
        Replies.find_by_question_id(id)
    end

    def followers
        QuestionFollows.followers_for_question_id(id)
    end

    def likers
        QuestionLikes.likers_for_question_id(id)
    end

    def num_likes
        QuestionLikes.num_likes_for_question_id(id)
    end

end

class Users

    attr_accessor :id, :fname, :lname

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM users")
        data.map { |datum| Users.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            users
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        Users.new(data.first)
    end

    def self.find_by_name(fname, lname)
        data = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
        SELECT
            *
        FROM
            users
        WHERE
            fname = ? AND lname = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Users.new(datum) } # people may have the same name
    end

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end


    def authored_questions
        Questions.find_by_associated_author_id(id)
    end

    def authored_replies
        Replies.find_by_user_id(id)
    end

    def followed_questions
        QuestionFollows.followed_questions_for_user_id(id)
    end

    def liked_questions
        QuestionLikes.liked_questions_for_user_id(id)
    end

    def average_karma
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            CAST(COUNT(question_likes.id) / COUNT(DISTINCT(questions.id)) AS FLOAT)
        FROM
            questions
        LEFT JOIN
            question_likes ON question_likes.question_id = questions.id
        WHERE questions.id = ?

        SQL
        return nil unless data.length > 0
        data
        # data.first.values.last / data.first.values.first
    end

end

class QuestionLikes

    attr_accessor :id, :user_id, :question_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_likes")
        data.map { |datum| QuestionLikes.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            question_likes
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        QuestionLikes.new(data.first)
    end

    def self.likers_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            users.id, fname, lname
        FROM
            question_likes
        JOIN
            users ON question_likes.user_id = users.id
        WHERE
            question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Users.new(datum) }

    end

    def self.num_likes_for_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            COUNT(users.id)
        FROM
            question_likes
        JOIN
            users ON question_likes.user_id = users.id
        WHERE
            question_id = ?
        SQL
        return nil unless data.length > 0
        data.first.values.first
    end

    def self.liked_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            question_likes
        JOIN
            questions ON question_likes.question_id = questions.id
        WHERE
            user_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Questions.new(datum) }
    end

    def self.most_liked_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL)
        SELECT
            *
        FROM
            question_likes
        JOIN
            questions ON question_likes.question_id = questions.id
        GROUP BY
            questions.id
        ORDER BY
            COUNT(questions.id) DESC
        SQL
        data.map { |datum| Questions.new(datum) }.take(n)
    end


    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end
end


class QuestionFollows

    attr_accessor :id, :user_id, :question_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM question_follows")
        data.map { |datum| QuestionFollows.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            question_follows
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        QuestionFollows.new(data.first)
    end

    def self.most_followed_questions(n)
        data = QuestionsDatabase.instance.execute(<<-SQL)
        SELECT
            *
        FROM
            question_follows
        JOIN
            questions ON question_follows.question_id = questions.id
        GROUP BY
            question_id
        ORDER BY
            COUNT(*) DESC
        SQL
        return nil unless data.length > 0
        data.map { |datum| Questions.new(datum) }.take(n)
    end

    def self.followers_for_question_id(question_id)
        #make an inner join
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            users
        JOIN
            question_follows ON question_follows.user_id = users.id
            --whichever is the primary key will get passed in as the new key. In this case users.id
        WHERE
            question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Users.new(datum) }
    end

    def self.followed_questions_for_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                *
            FROM
                questions
            JOIN
                question_follows ON question_follows.question_id = questions.id
                --whichever is the primary key will get passed in as the new key. In this case users.id
            WHERE
                user_id = ?
            SQL
        return nil unless data.length > 0
        data.map { |datum| Questions.new(datum) }
    end

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end
end


class Replies

    attr_accessor :id, :body, :user_id, :question_id, :parent_reply_id

    def self.all
        data = QuestionsDatabase.instance.execute("SELECT * FROM replies")
        data.map { |datum| Replies.new(datum) }
    end

    def self.find_by_id(id)
        data = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE
            id = ?
        SQL
        return nil unless data.length > 0
        Replies.new(data.first)
    end

    def self.find_by_user_id(user_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            replies
        WHERE
            user_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Replies.new(datum) } # users may submit many replies and we would want to get all of them
    end

    def self.find_by_parent_reply_id(parent_reply_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, parent_reply_id)
        SELECT
            *
        FROM
            replies
        WHERE
            parent_reply_id = ?
        SQL
        return nil unless data.length > 0
        Replies.new(data.first)
    end

    def self.find_by_question_id(question_id)
        data = QuestionsDatabase.instance.execute(<<-SQL, question_id)
        SELECT
            *
        FROM
            replies
        WHERE
            question_id = ?
        SQL
        return nil unless data.length > 0
        data.map { |datum| Replies.new(datum) } # this is because we get multiple values back and .first was only returining the first one. There may be more than one reply per question
    end

    def initialize(options)
        @id = options['id']
        @body = options['body']
        @user_id = options['user_id']
        @question_id = options['question_id']
        @parent_reply_id = options['parent_reply_id']
    end

    def author
        Users.find_by_id(user_id)
    end

    def question
        Questions.find_by_id(question_id)
    end

    def parent_reply
        Replies.find_by_id(parent_reply_id)
    end

    def child_replies
        # we want to find the nodes that have the parent_reply id of our current id.
        Replies.find_by_parent_reply_id(id)
    end

end






# # p Replies.find_by_user_id(1)
# # p Replies.find_by_question_id(2)
# a = Users.find_by_id(1)
# b = Questions.find_by_id(1)
# # c = Replies.find_by_id(2)
# # p a.authored_questions
# # p a.authored_replies
# # p b.author
# # p b.replies
# p a.followed_questions
# puts
# p b.followers
# # p QuestionFollows.find_by_id(1)
# p QuestionFollows.most_followed_questions(1)
# p QuestionLikes.liked_questions_for_user_id(3)
# p QuestionLikes.liked_questions_for_user_id(2)
# p QuestionLikes.liked_questions_for_user_id(1)

# p Questions.most_liked(2)

# p b.likers
# p b.num_likes

# p a.liked_questions

# p a.average_karma
a = Questions.new('id' => 1, 'title' => 'test_updated', 'body' => 'test', 'associated_author_id' => 1)
a.save