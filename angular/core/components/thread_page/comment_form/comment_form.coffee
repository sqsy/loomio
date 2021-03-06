angular.module('loomioApp').directive 'commentForm', ->
  scope: {discussion: '='}
  restrict: 'E'
  templateUrl: 'generated/components/thread_page/comment_form/comment_form.html'
  replace: true
  controller: ($scope, $rootScope, FormService, Records, Session, KeyEventService, AbilityService, ScrollService, EmojiService, ModalService, SignInForm) ->

    $scope.$on 'disableCommentForm', -> $scope.submitIsDisabled = true
    $scope.$on 'enableCommentForm',  -> $scope.submitIsDisabled = false

    $scope.showCommentForm = ->
      AbilityService.canAddComment($scope.discussion)

    $scope.isLoggedIn = AbilityService.isLoggedIn

    $scope.signIn = ->
      ModalService.open SignInForm

    $scope.threadIsPublic = ->
      $scope.discussion.private == false

    $scope.threadIsPrivate = ->
      $scope.discussion.private == true

    successMessage = ->
      if $scope.comment.isReply()
        'comment_form.messages.replied'
      else
        'comment_form.messages.created'
    successMessageName = ->
      if $scope.comment.isReply()
        $scope.comment.parent().authorName()

    $scope.listenForSubmitOnEnter = ->
      KeyEventService.submitOnEnter $scope
    $scope.$on 'voteCreated',     $scope.listenForSubmitOnEnter
    $scope.$on 'proposalCreated', $scope.listenForSubmitOnEnter

    $scope.init = ->
      $scope.comment = Records.comments.build(discussionId: $scope.discussion.id)
      $scope.submit = FormService.submit $scope, $scope.comment,
        draftFields: ['body']
        submitFn: $scope.comment.save
        flashSuccess: successMessage
        flashOptions:
          name: successMessageName
        successCallback: $scope.init
      $scope.listenForSubmitOnEnter()
    $scope.init()

    $scope.$on 'replyToCommentClicked', (event, parentComment) ->
      $scope.comment.parentId = parentComment.id
      ScrollService.scrollTo('.comment-form__comment-field')

    $scope.$on 'attachmentRemoved', (event, attachmentId) ->
      ids = $scope.comment.newAttachmentIds
      ids.splice ids.indexOf(attachmentId), 1

    $scope.bodySelector = '.comment-form__comment-field'
    EmojiService.listen $scope, $scope.comment, 'body', $scope.bodySelector

    $scope.updateMentionables = (fragment) ->
      regex = new RegExp("(^#{fragment}| +#{fragment})", 'i')
      allMembers = _.filter $scope.discussion.group().members(), (member) ->
        return false if member.id == Session.user().id
        (regex.test(member.name) or regex.test(member.username))
      $scope.mentionables = allMembers.slice(0, 5)

    $scope.fetchByNameFragment = (fragment) ->
      $scope.updateMentionables(fragment)
      Records.memberships.fetchByNameFragment(fragment, $scope.discussion.group().key).then ->
        $scope.updateMentionables(fragment)
