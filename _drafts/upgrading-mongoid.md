# a bunch of comments about what has changed

* `order` method doesn't exist anymore;
* `exists` doesn't take parameters anymore, use `where(conditions).exists?`;
* `find(:first)` and `find(:all)` are gone;
* timestamps returned in UTC;
* `BSON::ObjectId.convert` is gone and it isn't necessary anymore;
* setting :_id when creating mongoid model doesn't work anymore, it's attr_protected by default;
* `inc` a deeply nested hash (`ocr_page_count.data`) does not work;
* `find` with a collection of ids now requires all ids to match;
* `remove_attributes_missing_from_schema` at `item.rb` gets called before any attributes are set so it never does anything;