# frozen_string_literal: true

module Avcm::Sql
  SCHEMA = <<-SQL
    create table if not exists clips (
      id integer primary key,
      name string,
      start_time string not null,
      end_time string not null,
      path string not null,
      tags string,
      rating integer,
      sequence_id integer unique,
      sequence_index integer
    );
  SQL

  SELECT_FOR_LOOPER =
    'select name, start_time, end_time, path, sequence_id from clips'

  UNRATED_AND_UNTAGGED_CLIPS = <<-SQL
    #{SELECT_FOR_LOOPER}
    where rating is NULL and tags is NULL order by random() limit ?
  SQL

  UNRATED_XOR_UNTAGGED_CLIPS = <<-SQL
    #{SELECT_FOR_LOOPER}
    where (rating is NULL and tags is not NULL) or (rating is not null and tags is null) and name not in (%s)
    order by random() limit ?
  SQL

  RATED_AND_TAGGED_CLIPS = <<-SQL
    #{SELECT_FOR_LOOPER}
    where rating is not null and tags is not null and name not in (%s)
    order by random() limit ?
  SQL

  HIGH_SCORED_CLIPS = <<-SQL
    #{SELECT_FOR_LOOPER}
    where rating > 85
    order by random() limit ?
  SQL

  SEQUENCES = <<-SQL
    #{SELECT_FOR_LOOPER}
    where sequence_id is not null
    order by sequence_id asc, sequence_index asc limit ?
  SQL

  FIND_SEQUENCE = <<-SQL
    select name, start_time, end_time, path from clips
    where sequence_id = ?
    order by sequence_index asc
  SQL

  STRATEGIES = {
    discovery: [UNRATED_AND_UNTAGGED_CLIPS, UNRATED_XOR_UNTAGGED_CLIPS],
    default: [UNRATED_AND_UNTAGGED_CLIPS, UNRATED_XOR_UNTAGGED_CLIPS,
              RATED_AND_TAGGED_CLIPS],
    high_score: [HIGH_SCORED_CLIPS], sequences: [SEQUENCES],
    export: []
  }.freeze
end
