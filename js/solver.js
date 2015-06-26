(function() {
  var WordFinder,
    slice = [].slice;

  WordFinder = (function() {
    var PLACEHOLDERS;

    PLACEHOLDERS = /[a-zA-Z0-9_!?-]/;

    function WordFinder(data1) {
      this.data = data1;
      this.candidateGroups = {};
      this.symbols = {};
    }

    WordFinder.prototype.addWord = function(word) {
      var matched, pattern, ref, symbolInfos, textData;
      textData = this.data[word.length];
      ref = this.makeSearchPattern(word), pattern = ref[0], symbolInfos = ref[1];
      _.keys(symbolInfos).forEach((function(_this) {
        return function(v) {
          return _this.symbols[v] = true;
        };
      })(this));
      matched = textData.match(new RegExp("^" + pattern + "$", 'gm'));
      return this.candidateGroups[word] = {
        symbolInfos: symbolInfos,
        candidates: (matched || []).map((function(_this) {
          return function(word) {
            return _this.extractCandidate(word, symbolInfos);
          };
        })(this))
      };
    };

    WordFinder.prototype.makeSearchPattern = function(word) {
      var count, symbolInfos;
      symbolInfos = {};
      count = 0;
      return [
        word.split('').map(function(ch, i) {
          if (ch.match(PLACEHOLDERS)) {
            if (symbolInfos[ch]) {
              return "\\" + symbolInfos[ch].backRefCount;
            } else {
              symbolInfos[ch] = {
                stringIndex: i,
                backRefCount: ++count
              };
              return "(.)";
            }
          } else {
            return ch;
          }
        }).join(''), symbolInfos
      ];
    };

    WordFinder.prototype.extractCandidate = function(word, symbolInfos) {
      return _.mapObject(symbolInfos, function(info) {
        return word[info.stringIndex];
      });
    };

    WordFinder.prototype.filterGroupsBySymbol = function(groups, symbol) {
      return _.pick(groups, function(group) {
        return _.has(group.symbolInfos, symbol);
      });
    };

    WordFinder.prototype.narrow = function(groups, symbol) {
      var keyArrays, narrowed;
      keyArrays = _.values(groups).map(function(group) {
        return group.candidates.map(function(candidate) {
          return candidate[symbol];
        });
      });
      narrowed = _.intersection.apply(_, keyArrays);
      return _.mapObject(groups, function(group) {
        return _.extend(group, {
          candidates: group.candidates.filter(function(candidate) {
            return narrowed.some(function(char) {
              return candidate[symbol] === char;
            });
          })
        });
      });
    };

    WordFinder.prototype.buildResults = function(candidatesList, candidate) {
      var candidates, pred;
      if (candidate == null) {
        candidate = {};
      }
      pred = function(cand) {
        return _.pairs(cand).every(function(arg) {
          var char, symbol;
          symbol = arg[0], char = arg[1];
          return !_.has(candidate, symbol) || candidate[symbol] === char;
        });
      };
      candidates = _.first(candidatesList).filter(pred);
      if (candidatesList.length === 1) {
        return candidates.map(function(c) {
          return _.extend(_.clone(candidate), c);
        });
      } else {
        return _.flatten(candidates.map((function(_this) {
          return function(c) {
            return _this.buildResults(_.rest(candidatesList), _.extend(_.clone(candidate), c));
          };
        })(this)), 1);
      }
    };

    WordFinder.prototype.getResults = function() {
      var groups;
      groups = _.reduce(_.keys(this.symbols), (function(_this) {
        return function(candidateGroups, symbol) {
          var filteredGroup, narrowed;
          filteredGroup = _this.filterGroupsBySymbol(candidateGroups, symbol);
          narrowed = _this.narrow(filteredGroup, symbol);
          return _.extend(candidateGroups, narrowed);
        };
      })(this), this.candidateGroups);
      return _.uniq(this.buildResults(_.values(groups).map(function(o) {
        return o.candidates;
      })));
    };

    return WordFinder;

  })();

  $(function() {
    var charNums, data;
    data = null;
    charNums = ['2', '3', '4', '5'];
    $.when.apply($, (charNums.map(function(n) {
      return $.ajax("data/" + n + "words.txt");
    }))).done(function() {
      var args;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return data = _.object(charNums, args.map(_.first));
    });
    return $('#search').on('click', function() {
      var $result_area, finder, limit, resultHTML, resultStrings, results, slopped, words;
      $result_area = $('#result-area');
      if (data === null) {
        $result_area.text('データダウンロード中');
        return;
      }
      finder = new WordFinder(data);
      words = $('#input-area').val().split(/\s+/).filter(_.identity);
      if (words.length === 0) {
        $result_area.text('単語を入力してください');
        return;
      }
      words.forEach(function(word) {
        return finder.addWord(word);
      });
      limit = 5;
      results = finder.getResults();
      if (results.length === 0) {
        resultHTML = "<div>見付かりませんでした</div>";
      } else {
        slopped = results.length - limit;
        results = results.slice(0, limit);
        resultStrings = results.map(function(result) {
          return _.pairs(result).map(function(arg) {
            var symbol, value;
            symbol = arg[0], value = arg[1];
            return symbol + "=" + value;
          }).join(" ");
        });
        resultHTML = resultStrings.map(function(text) {
          return "<div>" + text + "</div>";
        }).join("\n");
        if (0 < slopped) {
          resultHTML += "<div>他 " + slopped + " 件</div>";
        }
      }
      return $result_area.html(resultHTML);
    });
  });

}).call(this);

//# sourceMappingURL=maps/solver.js.map