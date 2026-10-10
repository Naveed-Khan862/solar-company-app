import 'package:flutter_test/flutter_test.dart';

import 'package:solar_company_project/utils/chat_access.dart';

void main() {
  test('request chat: sender + request parties + CEO, sorted + lowercase', () {
    final p = participantsFor(
      channel: 'request:R1',
      senderEmail: 'owner@x.com',
      userEmail: 'Owner@X.com',
      assignedTo: 'Sub@X.com',
      ceoEmails: ['CEO@X.com'],
    );
    expect(p, ['ceo@x.com', 'owner@x.com', 'sub@x.com']);
  });

  test('unassigned request: no empty participant', () {
    final p = participantsFor(
      channel: 'request:R1',
      senderEmail: 'owner@x.com',
      userEmail: 'owner@x.com',
      assignedTo: '',
      ceoEmails: ['ceo@x.com'],
    );
    expect(p, ['ceo@x.com', 'owner@x.com']);
  });

  test('admin channel = staff only (CEO + subAdmins)', () {
    final p = participantsFor(
      channel: 'admin',
      senderEmail: 'ceo@x.com',
      ceoEmails: ['ceo@x.com'],
      subAdminEmails: ['s1@x.com', 's2@x.com'],
    );
    expect(p, ['ceo@x.com', 's1@x.com', 's2@x.com']);
  });

  test('team channel = owner + members + sender', () {
    final p = participantsFor(
      channel: 'team:sub@x.com',
      senderEmail: 'member1@x.com',
      ownerEmail: 'sub@x.com',
      memberEmails: ['member1@x.com', 'Member2@X.com'],
    );
    expect(p, ['member1@x.com', 'member2@x.com', 'sub@x.com']);
  });

  test('support = sender + staff', () {
    final p = participantsFor(
      channel: 'support',
      senderEmail: 'client@x.com',
      ceoEmails: ['ceo@x.com'],
      subAdminEmails: ['s1@x.com'],
    );
    expect(p, ['ceo@x.com', 'client@x.com', 's1@x.com']);
  });

  test('subadmins channel: sender is member (case-insensitive)', () {
    final p = participantsFor(
      channel: 'subadmins',
      senderEmail: 'S1@X.com',
      subAdminEmails: ['s1@x.com', 's2@x.com'],
    );
    expect(p, ['s1@x.com', 's2@x.com']);
  });
}